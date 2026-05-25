{ pkgs, lib, config, unstable, llmAgent, ... }:

let
  latestLlamaCpp = (pkgs.llama-cpp.override {
    cudaSupport = true;
    blasSupport = true;
  }).overrideAttrs (oldAttrs: rec {
    version = "9084";
    src = pkgs.fetchFromGitHub {
      owner = "ggml-org";
      repo = "llama.cpp";
      tag = "b${version}";
      hash = "sha256-PKCuImYMZ2zaEt3toL3p7TZPPJuFTwl6BilCT1B1Wyo=";
      leaveDotGit = true;
      postFetch = ''
        git -C "$out" rev-parse --short HEAD > $out/COMMIT
        find "$out" -name .git -print0 | xargs -0 rm -rf
      '';
    };
    npmDepsHash = "sha256-cV3noOyKmst9vfxyvkCNhihPgwfVGhmPPT4UMloeWZM=";
    cmakeFlags = builtins.filter
      (f: !(lib.hasPrefix "-DGGML_NATIVE=" f))
      (oldAttrs.cmakeFlags or [])
    ++ [ (lib.cmakeBool "GGML_NATIVE" true) ];
    preConfigure = ''
      export NIX_ENFORCE_NO_NATIVE=0
      ${oldAttrs.preConfigure or ""}
    '';
  });

  llamaServer = lib.getExe' latestLlamaCpp "llama-server";
  vllmServer = lib.getExe' pkgs.python313Packages.vllm "vllm";
in
{
  imports = [
    ./hardware.nix

    ../../modules/gui/steam.nix
    ../../modules/gui/xmonad.nix
    ../../modules/services/docker.nix
    ../../modules/services/ssh.nix
    ../../modules/system/boot.nix
    ../../modules/system/core.nix
    ../../modules/system/nix.nix
    ../../modules/system/users.nix
    ../../modules/system/zswap.nix
    ../../modules/services/searxng.nix
    ../../modules/services/porkbun-ddns.nix
  ];

  # Agenix secrets
  age.secrets."searxng-secret" = {
    file = ./secrets/searxng-secret.age;
    owner = "searx";
    group = "searx";
  };

  age.secrets."grafana-secret" = {
    file = ./secrets/grafana-secret.age;
    owner = "grafana";
    group = "grafana";
  };

  age.secrets."porkbun-api-key" = {
    file = ./secrets/porkbun-api-key.age;
    owner = "root";
  };

  age.secrets."porkbun-secret-key" = {
    file = ./secrets/porkbun-secret-key.age;
    owner = "root";
  };

  # Inject searxng secret via environment file
  services.searx.environmentFile = config.age.secrets."searxng-secret".path;

  system.stateVersion = "24.11";
  networking.hostName = "pigs-desktop";

  zramSwap = {
    enable = true;

    # Single device is recommended and sufficient
    swapDevices = 1;

    # 22% of 128GB ≈ 28GB of zram — enough to absorb compilation bursts
    # without wasting address space. zstd on compiler memory gets ~3-4x
    # compression so effective headroom is ~80-100GB of burst.
    memoryPercent = 22;

    # Hard cap as a safety net — zstd can be CPU-hungry under extreme
    # pressure, and you don't want zram itself becoming a bottleneck
    memoryMax = 30 * 1024 * 1024 * 1024; # 30GB in bytes

    # zstd: best compression ratio for compiler workloads (AST, IR, etc.)
    # lz4 would be faster to compress/decompress but worse ratio — not
    # worth it here since you're not swap-bound during inference
    algorithm = "zstd";

    # High priority so zram is always preferred over any disk swap
    # Default is 5; keeping it explicit
    priority = 100;

    # No writeback device — as discussed, disk swap isn't worth it
    # for your use case
    writebackDevice = null;
  };

  # zswap.enable = true;

  nixpkgs.config.problems.handlers = {
    flashinfer.broken = "ignore"; # or "warn" if you want to see a warning
  };



nix.settings = {
  cores = 64;        # per-job parallelism (make -j)
  max-jobs = 8;     # only 1 derivation building at a time
};

nixpkgs.config = {
  allowUnfree = true;
  cudaSupport = true;
  cudaCapabilities = [ "8.6" ];
  cudaForwardCompat = false;
};

nix.settings = {
  substituters = [
    "https://cache.nixos-cuda.org"
  ];
  trusted-public-keys = [
    "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
  ];
};

nixpkgs.overlays = [
  (final: prev: let
    mineruVlUtils = prev.python313.pkgs.buildPythonPackage {
      pname = "mineru_vl_utils";
      version = "0.2.6";
      src = prev.fetchFromGitHub {
        owner = "opendatalab";
        repo = "mineru-vl-utils";
        rev = "mineru_vl_utils-0.2.7-released";
        sha256 = "3066a66bd3786d98742eb5bfa5847e8f6f43e2078f83b168d4012899f372e237";
      };
      format = "pyproject";
      nativeBuildInputs = with prev.python313.pkgs; [ setuptools wheel ];
      dependencies = with prev.python313.pkgs; [
        httpx
        httpx-retries
        aiofiles
        pillow
        pydantic
        loguru
      ];
      doCheck = true;
    };
  in {
    "cuda12.9-libnvshmem" = prev."cuda12.9-libnvshmem".overrideAttrs (old: {
      cmakeFlags = (old.cmakeFlags or []) ++ [
        "-DNVSHMEM_BUILD_EXAMPLES=OFF"
        "-DNVSHMEM_BUILD_TESTS=OFF"
      ];
    });
    magma = prev.magma.overrideAttrs (_: { doCheck = false; });
    magma-cuda = prev.magma-cuda.overrideAttrs (_: { doCheck = false; });

    python313 = prev.python313.override {
      packageOverrides = pyFinal: pyPrev: {
        sse-starlette = pyPrev.sse-starlette.overridePythonAttrs (old: {
          doCheck = false;
          dependencies = (old.dependencies or []) ++ [ pyFinal.starlette ];
        });
        cuda-pathfinder = pyPrev.cuda-pathfinder.overridePythonAttrs (old: {
          doCheck = false;
        });
        jupyter-server = pyPrev.jupyter-server.overridePythonAttrs (old: {
          doCheck = false;
        });
        jupyterlab = pyPrev.jupyterlab.overridePythonAttrs (old: {
          doCheck = false;
          dependencies = (old.dependencies or []) ++ [ pyFinal.jupyterlab-server ];
        });
        torch =   let
          torchWithCuda = pyPrev.torch.override {
            cudaSupport = true;
            cudaPackages = final.cudaPackages;
          };
        in
          torchWithCuda.overridePythonAttrs (old: {
            doCheck = false;
            doInstallCheck = false;
            env = (old.env or {}) // {
              TORCH_CUDA_ARCH_LIST = "8.6";
            };
          });
        vllm = let
          vllmFast = pyPrev.vllm.override {
            cudaSupport = true;
            cudaPackages = final.cudaPackages;
          };
          triton-src = final.fetchFromGitHub {
            owner = "triton-lang";
            repo = "triton";
            rev = "v3.5.0";
            hash = "sha256-F6T0n37Lbs+B7UHNYzoIQHjNNv3TcMtoXjNrT8ZUlxY=";
          };
        in
          vllmFast.overridePythonAttrs (old: {
            dependencies = (old.dependencies or []) ++ [ pyFinal.triton mineruVlUtils ];
            env.NIX_BUILD_CORES = "48";
            env.MAX_JOBS = "48";
            env.VLLM_TARGET_DEVICE = "cuda";
            env.CMAKE_ARGS = builtins.concatStringsSep " " [
              "-DFETCHCONTENT_SOURCE_DIR_TRITON_KERNELS=${triton-src}"
              "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
            ];
          });
        triton = pyPrev.triton.overridePythonAttrs (old: {
          doCheck = false;
          preConfigure = ''
            export MAX_JOBS=1
          '';
          passthru = (old.passthru or {}) // {
            override = attrs: pyPrev.triton.override attrs;
          };
        });
        triton-cuda = pyPrev.triton-cuda.overridePythonAttrs (old: {
          doCheck = false;
          preConfigure = ''
            export MAX_JOBS=1
        '';
        });
        mistral-common = pyPrev.mistral-common.overridePythonAttrs (old: rec {
          doCheck = false;
          version = "1.10.0";
          src = prev.fetchPypi {
            pname = "mistral_common";
            inherit version;
            sha256 = "sha256-5Fb/EB7b38CUA57Gwm99D3M1Zyl5jWKKbm6Ww5FxR7w=";
          };
        });
      };
    };
    python313Packages = final.python313.pkgs;
  })
];

environment.systemPackages = with pkgs; [
  nvtopPackages.nvidia

    (pkgs.writeShellScriptBin "pi-node" ''
      export PATH=${nodejs}/bin:${python3}/bin:$PATH
      exec ${pi-coding-agent}/bin/pi "$@"
    '')
    # pi-coding-agent
    # (pkgs.pi-coding-agent.overrideAttrs (oldAttrs: rec {
    #   version = "0.73.1";
    #   src = pkgs.fetchurl {
    #     url = "https://registry.npmjs.org/@mariozechner/pi-coding-agent/-/pi-coding-agent-${version}.tgz";
    #     hash = "sha256-e/XUkmcMBP18WZ3ufm6qv/lkCEr/0hZ2YQfmdB33ouE=";
    #   };
    #   # npmDepsHash = "sha256-...";
    # }))
  ];

  # Define VPN network namespace
  vpnNamespaces.wg = {
    enable = true;
    wireguardConfigFile = "/media/data/.secret/wg.conf";
    accessibleFrom = [
      "192.168.1.0/24"
    ];
    portMappings = [
      { from = 9091; to = 9091; }
    ];
    openVPNPorts = [{
      port = 60729;
      protocol = "both";
    }];
  };

  # Add systemd service to VPN network namespace
  systemd.services.transmission.vpnConfinement = {
    enable = true;
    vpnNamespace = "wg";
  };

  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
    settings.download-dir = "/media/data/torrents";
    settings.incomplete-dir = "/media/data/torrents/incomplete";
    group = "media";
    settings = {
      "rpc-bind-address" = "192.168.15.1"; #"10.2.0.2"; # Bind RPC/WebUI to VPN network namespace address

      "rpc-whitelist" = "127.0.0.1,192.168.1.*,192.168.15.5";  # Access from other machines on specific subnet
    };
  };

  services.radarr = {
    enable = true;
    openFirewall = true;
    group = "media";
  };

  services.sonarr = {
    enable = true;
    openFirewall = true;
    group = "media";
  };

  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };

  services.seerr = {
    enable = true;
    openFirewall = true;
  };

  services.flaresolverr = {
    enable = true;
    openFirewall = true;
  };

  services.jellyfin = {
    enable = true;
    openFirewall = true;
    group = "media";
  };

  users.groups.media = {};

  systemd.tmpfiles.rules = [
    "d /media/data 2775 root media - -"
    "d /media/data/torrents 2775 root media - -"
    "d /media/data/torrents/movies 2775 root media - -"
    "d /media/data/torrents/tv 2775 root media - -"
    "d /media/data/torrents/incomplete 2775 root media - -"
    "d /media/data/media 2775 root media - -"
    "d /media/data/media/movies 2775 root media - -"
    "d /media/data/media/tv 2775 root media - -"
    "d /media/data/media/sports 2775 root media - -"
  ];

  #services.immich = {
  #  enable = true;
  #  openFirewall = true;
  #  host = "0.0.0.0";
  #};

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = true;

  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /srv/nfs      192.168.1.0/24(rw,fsid=0,no_subtree_check)
    /srv/nfs/pigs 192.168.1.0/24(rw,fsid=12345,nohide,insecure,no_subtree_check)
    /srv/nfs/stardew 192.168.1.0/24(rw,sync,no_root_squash,anonuid=1000,anongid=1000)
  '';

  #networking.firewall.allowedTCPPorts = [ 2049 ];

  boot.zfs.forceImportRoot = false;
  boot.supportedFilesystems = [ "zfs" ];
  # boot.zfs.extraPools = [ "tank/storage" ];

  networking.hostId = "d82ba9f7"; # REQUIRED for ZFS (any 8 hex chars)

  services.zfs = {
    autoScrub.enable = true;
  };



#     extraFlags = [
#       "-ngl" "999"
#       "--main-gpu" "0"
#       # "--split-mode" "none"
#       "--split-mode" "layer"
#       # "--kv-unified"
#       # "--tensor-split" "24,10"
#       "--tensor-split" "0.75,0.25
# "
#       # "--fit" "on"
#       # "--fit-ctx" "128000"
#       # "--fit-ctx" "262144"
#       # "--fit-target" "256"
#       "--parallel" "1"
#       "--no-mmap" "--mlock"
#       "-b" "2048" "-ub" "2048"
#       "--temp" "0.6"
#       "--top-p" "0.95"
#       "--top-k" "20"
#       "--min-p" "0.0"
#       "--presence-penalty" "0.0"
#       "--repeat-penalty" "1.0"
#       "--reasoning-budget" "-1"
#       "--chat-template-kwargs" "{\"preserve_thinking\": true}"
#       # "--chat-template-kwargs" "{\"enable_thinking\": true, \"preserve_thinking\": true}"

#       "--cache-type-k" "q8_0" "--cache-type-v" "q8_0"
#       "--flash-attn" "on"


#       # Context "16384" "32768" "65536" "131072"
#       "-c" "264000"
#       # "-c" "262144"

#       # CPU layers will run on the 3975wx — use most of your 32 cores
#       # "-t" "28"

#       # Larger batch helps amortise the CPU↔GPU transfer overhead
#       # "-b" "2048"
#       # "--ubatch-size" "512"

#       # "--numa" "numactl"

#       # "--keep" "-1"

#       # "--jinja"
#      # mmap can actually help here since CPU-side layers page from disk/RAM
#       # remove --no-mmap so the OS can manage CPU-resident layers efficiently
#     ];
#   };

  services.llama-swap = {
    enable = true;
    listenAddress = "0.0.0.0";
    port = 11444;
    openFirewall = true;

    settings = {
      healthCheckTimeout = 300;
      # logLevel = "debug";
      # logToStdout = "both";
      models = {
        "Qwen3.6-27B-UD-Q4_K_XL" = {
          proxy = "http://0.0.0.0:11445";
          cmd = ''
            ${llamaServer} --port 11445 \
              -m /fast/llama-cpp/models/Qwen3.6-27B-UD-Q4_K_XL.gguf \
              --no-webui \
              --metrics \
              -ngl 999 \
              --main-gpu 0 \
              --split-mode layer \
              --tensor-split 0.75,0.25 \
              --parallel 1 \
              --no-mmap --mlock \
              -b 2048 -ub 2048 \
              --temp 0.6 \
              --top-p 0.95 \
              --top-k 20 \
              --min-p 0.0 \
              --presence-penalty 0.0 \
              --repeat-penalty 1.0 \
              --reasoning-budget -1 \
              --chat-template-kwargs "{\"preserve_thinking\": true}" \
              --cache-type-k q8_0 --cache-type-v q8_0 \
              --flash-attn on \
              --no-mmproj-offload \
              -c 164000
          '';
        };
        "MinerU2.5-Pro-2604-1.2B" = {
          proxy = "http://0.0.0.0:11445";
          cmd = ''
            env VLLM_CACHE_ROOT=/tmp \
            ${vllmServer} serve \
              /fast/llama-cpp/models/MinerU2.5-Pro-2604-1.2B \
              --served-model-name MinerU2.5-Pro-2604-1.2B \
              --port 11445 \
              --host 0.0.0.0 \
              --logits-processors mineru_vl_utils:MinerULogitsProcessor
          '';
        };
      };
    };
  };
systemd.services.llama-swap = {
  serviceConfig = {
    ProtectProc = lib.mkForce "default";
    ProcSubset = lib.mkForce "all";
    ProtectSystem = lib.mkForce "false";
    PrivateTmp = lib.mkForce false;
    PrivateMounts = lib.mkForce false;
    RestrictNamespaces = lib.mkForce false;
    MemoryDenyWriteExecute = lib.mkForce false;
    ProtectHome = lib.mkForce "false";
    PrivateUsers = lib.mkForce false;
    RestrictAddressFamilies = lib.mkForce [
      "AF_INET"
      "AF_INET6"
      "AF_UNIX"
      "AF_NETLINK"
    ];
    Environment = [
      # "VLLM_CACHE_ROOT=/tmp"
      "HOME=/tmp"
      "HF_HOME=/tmp/huggingface"
      "VLLM_CACHE_ROOT=/tmp/vllm"
      "XDG_CACHE_HOME=/tmp/cache"
      "TRITON_CACHE_DIR=/tmp/triton"
    ];
  };
};
  # services.open-webui = {
  #   enable = true;
  #   openFirewall = true;
  #   host = "0.0.0.0";
  # };

  services.prometheus = {
    enable = true;
    retentionTime = "90d";
    scrapeConfigs = [
      {
        job_name = "llama-server";
        static_configs = [{ targets = [ "localhost:11445" ]; }];
        metrics_path = "/metrics";
        scrape_interval = "1m";
      }
    ];
  };

  services.grafana = {
    enable = true;
    openFirewall = true;
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3001;
      };
    };
    # $__file{} is a Grafana runtime directive — reads the file at startup, not build time
    settings.security.secret_key = "$__file{${config.age.secrets."grafana-secret".path}}";

    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:9090";
          isDefault = true;
        }
      ];
    };
  };

  containers.smut = {
    config = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.pi-coding-agent pkgs.nodejs ];
      users.users.agent = {
        isNormalUser = true;
      };
      services.openssh.enable = true;
      system.stateVersion = "24.11";
    };
  };
}
