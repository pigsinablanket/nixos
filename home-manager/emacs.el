;; ---------------------------------------------------------------------
;; hooks
;; ---------------------------------------------------------------------

(add-hook 'prog-mode-hook     'rainbow-delimiters-mode)
(add-hook 'after-init-hook    'electric-pair-mode)
;;(add-hook 'prog-mode-hook     'untabify-mode)
(add-hook 'before-save-hook   'delete-trailing-whitespace)
(add-hook 'haskell-mode-hook  'haskell-indentation-mode)
(add-hook 'haskell-mode-hook  'global-ede-mode)
;;(add-hook 'markdown-mode-hook 'untabify-mode)
(add-hook 'after-init-hook    'global-auto-revert-mode)
;; (add-hook 'after-init-hook    'global-company-mode)
(add-hook 'after-init-hook    'ido-mode)

;; (add-hook 'prog-mode-hook 'display-line-numbers-mode)

(add-hook 'go-mode-hook 'lsp-deferred)
;;(add-hook 'go-mode-hook 'subword-mode)
;; (add-hook 'before-save-hook 'gofmt-before-save)

(add-to-list 'warning-suppress-types '(lsp-mode))

(add-hook 'go-mode-hook
          (lambda ()
            (add-hook 'before-save-hook #'gofmt-before-save nil t)))

(setq company-idle-delay 0)
(setq company-minimum-prefix-length 1)
(add-hook 'go-mode-hook (lambda () (setq tab-width 2)))
;; Go - lsp-mode
;; Set up before-save hooks to format buffer and add/delete imports.
;;(defun lsp-go-install-save-hooks ()
;;  (add-hook 'before-save-hook #'lsp-format-buffer t t)
;;  (add-hook 'before-save-hook #'lsp-organize-imports t t))
;;(add-hook 'go-mode-hook #'lsp-go-install-save-hooks)

;;(global-flycheck-mode)
;;(add-hook 'go-mode-hook (lambda ()
;;                          (setq tab-width 4)
;;                          (flycheck-add-next-checker 'lsp 'go-vet)
;;                          (flycheck-add-next-checker 'lsp 'go-staticcheck)))

;; ---------------------------------------------------------------------
;; keybindings
;; ---------------------------------------------------------------------

(global-set-key (kbd "M-x")   'smex)
(global-set-key (kbd "M-X")   'smex-major-mode-commands)
(global-set-key (kbd "C-x m") 'view-mode)
(global-set-key (kbd "M-;")   'comment-dwim-line)

;; ---------------------------------------------------------------------
;; customizations
;; ---------------------------------------------------------------------

;; highlight current line
(global-hl-line-mode 1)
(set-face-attribute 'hl-line nil :inherit nil :background "#000000")

(setq undo-tree-visualizer-diff 1)
(setq undo-tree-visualizer-timestamps 1)
(setq undo-tree-auto-save-history nil)

(setq typescript-indent-level 2)

;; tree undo mode
(global-undo-tree-mode)

;; show matching parens
(require 'paren)
(show-paren-mode 1)
(setq show-paren-delay 0)
(set-face-attribute 'show-paren-match nil :background "#493535")

;; cursor goes to same place from previous sessios
(save-place-mode 1)

;; read-only files open with view-mode
(setq view-read-only t)

;; highligh past 80 characters
(require 'whitespace)
(global-whitespace-mode t)
(setq whitespace-style '(face empty tabs lines-tail trailing))
(add-hook 'window-setup-hook
          (lambda ()
            (set-face-attribute 'whitespace-line nil
                                :foreground 'unspecified
                                :background "#404040")))

;; mode-line theme
(require 'spaceline-config)
(spaceline-spacemacs-theme)
(spaceline-toggle-buffer-size-off)

;; Enable ido
(setq ido-enable-flex-matching t)
(setq ido-case-fold t)

;; Use my-backup-file-name function to determine where to place backups
(setq make-backup-file-name-function 'my-backup-file-name)

(setq auto-mode-alist (append '(("\\.html$" . web-mode)) auto-mode-alist))
(setq auto-mode-alist (append '(("\\.php$" . web-mode)) auto-mode-alist))
(setq auto-mode-alist (append '(("\\.inc$" . web-mode)) auto-mode-alist))
(setq auto-mode-alist (append '(("\\.tsx$" . web-mode)) auto-mode-alist))
(setq auto-mode-alist (append '(("\\.ts$" . web-mode)) auto-mode-alist))
(defun my-web-mode-hook ()
  "Hooks for Web mode."
  (setq web-mode-code-indent-offset 2)
)
(add-hook 'web-mode-hook  'my-web-mode-hook)

(setq-default indent-tabs-mode nil)

;; Make haskell use unicode characters
(setq haskell-font-lock-symbols t)


(custom-set-variables
 '(ansi-color-faces-vector
   [default default default italic underline success warning error])
 '(ansi-color-names-vector
   ["#242424" "#e5786d" "#95e454" "#cae682" "#8ac6f2" "#333366" "#ccaa8f"
    "#f6f3e8"])
 '(custom-enabled-themes '(tango-dark)))

(custom-set-faces
 '(rainbow-delimiters-depth-1-face ((t (:foreground "dark orange"))))
 '(rainbow-delimiters-depth-2-face ((t (:foreground "deep pink"))))
 '(rainbow-delimiters-depth-3-face ((t (:foreground "chartreuse"))))
 '(rainbow-delimiters-depth-4-face ((t (:foreground "deep sky blue"))))
 '(rainbow-delimiters-depth-5-face ((t (:foreground "yellow"))))
 '(rainbow-delimiters-depth-6-face ((t (:foreground "orchid"))))
 '(rainbow-delimiters-depth-7-face ((t (:foreground "spring green"))))
 '(rainbow-delimiters-depth-8-face ((t (:foreground "sienna1"))))
 )


;; ---------------------------------------------------------------------
;; functions
;; ---------------------------------------------------------------------

;; make backup to a designated dir, mirroring the full path
(defun my-backup-file-name (fpath)
  "Return a new file path of a given file path.
  If the new path's directories does not exist, create them."
  (let* ((backupRootDir "~/.emacs.d/emacs-backup/")
         (filePath
          (replace-regexp-in-string "[A-Za-z]:" "" fpath ))
         (backupFilePath
          (replace-regexp-in-string "//" "/"
                                    (concat backupRootDir filePath "~"))))
    (make-directory
     (file-name-directory backupFilePath)
     (file-name-directory backupFilePath))
    backupFilePath)
)

;; untabify before saving
(defvar untabify-this-buffer)
(defun untabify-all ()
  "Untabify the current buffer, unless `untabify-this-buffer' is nil."
  (and untabify-this-buffer (untabify (point-min) (point-max)))
)
(define-minor-mode untabify-mode
  "Untabify buffer on save." nil " untab" nil
  (make-variable-buffer-local 'untabify-this-buffer)
  (setq untabify-this-buffer (not (derived-mode-p 'makefile-mode)))
  (add-hook 'before-save-hook #'untabify-all)
)

;; comment line rebinding
(defun comment-dwim-line (&optional arg)
  "Replacement for the comment-dwim command.
   If no region is selected and current line is not blank and we are not at the end of the line,
   then comment current line.
   Replaces default behaviour of comment-dwim, when it inserts comment at the end of the line."
  (interactive "*P")
  (comment-normalize-vars)
  (if (and (not (region-active-p)) (not (looking-at "[ \t]*$")))
      (comment-or-uncomment-region (line-beginning-position) (line-end-position))
    (comment-dwim arg)))

;; change color of haskell var starting with _
(defface haskell-underscore-face
  '((t :foreground "#ddaaaa"
       ))
  "Face for haskell vars underlined."
  :group 'my-lang-mode )
(font-lock-add-keywords 'haskell-mode
                        '(("_[a-z][a-zA-Z0-9]*" 0 'haskell-underscore-face)))

;; =============================================================================
;; Rust Development Configuration
;; All packages managed externally via Nix
;; =============================================================================

;; -----------------------------------------------------------------------------
;; Performance — raise GC threshold while LSP is active
;; -----------------------------------------------------------------------------
(setq gc-cons-threshold     (* 100 1024 1024)  ; 100MB
      read-process-output-max (*   1 1024 1024)) ; 1MB

;; -----------------------------------------------------------------------------
;; LSP Mode
;; -----------------------------------------------------------------------------
(require 'lsp-mode)

(setq lsp-rust-analyzer-server-command              '("rust-analyzer")
      lsp-idle-delay                                0.5
      lsp-log-io                                    nil   ; set t to debug

      ;; UI
      lsp-eldoc-render-all                          nil
      lsp-signature-auto-configure                  t
      lsp-headerline-breadcrumb-enable              t
      lsp-lens-enable                               t     ; inline run/test lens

      ;; rust-analyzer features
      lsp-rust-analyzer-cargo-watch-command         "clippy"
      lsp-rust-analyzer-display-chained-hint-types  t
      lsp-rust-analyzer-display-lifetime-elision-hints-enable "skip_trivial"
      lsp-rust-analyzer-display-closure-return-type-hints t
      lsp-rust-analyzer-display-parameter-hints     t
      lsp-rust-analyzer-display-reborrow-hints      nil)

(with-eval-after-load 'lsp-mode
  (define-key lsp-mode-map (kbd "C-c l r") #'lsp-rename)
  (define-key lsp-mode-map (kbd "C-c l a") #'lsp-execute-code-action)
  (define-key lsp-mode-map (kbd "C-c l d") #'lsp-find-definition)
  (define-key lsp-mode-map (kbd "C-c l R") #'lsp-find-references)
  (define-key lsp-mode-map (kbd "C-c l i") #'lsp-find-implementation)
  (define-key lsp-mode-map (kbd "C-c l h") #'lsp-describe-thing-at-point)
  (define-key lsp-mode-map (kbd "C-c l f") #'lsp-format-buffer))

;; -----------------------------------------------------------------------------
;; LSP UI
;; -----------------------------------------------------------------------------
(require 'lsp-ui)

(setq lsp-ui-doc-enable               t
      lsp-ui-doc-position             'at-point
      lsp-ui-doc-delay                0.5
      lsp-ui-doc-show-with-cursor     t
      lsp-ui-sideline-enable          t
      lsp-ui-sideline-show-diagnostics t
      lsp-ui-sideline-show-hover      nil   ; doc popup already covers this
      lsp-ui-sideline-show-code-actions t
      lsp-ui-peek-enable              t)

(with-eval-after-load 'lsp-ui
  (define-key lsp-ui-mode-map (kbd "M-.")     #'lsp-ui-peek-find-definitions)
  (define-key lsp-ui-mode-map (kbd "M-?")     #'lsp-ui-peek-find-references)
  (define-key lsp-ui-mode-map (kbd "C-c l u") #'lsp-ui-doc-toggle))

;; -----------------------------------------------------------------------------
;; rust-mode (base layer — rustic derives from this)
;; -----------------------------------------------------------------------------
(require 'rust-mode)

(setq rust-format-on-save nil   ; rustic owns formatting
      rust-indent-offset 2)

;; -----------------------------------------------------------------------------
;; Rustic
;; -----------------------------------------------------------------------------
(require 'rustic)

(setq rustic-lsp-client             'lsp-mode
      rustic-format-on-save         t
      rustic-format-trigger         'on-save
      rustic-compile-backtrace      "1"
      rustic-compile-display-method 'display-buffer
      rustic-test-arguments         "--color always")

(with-eval-after-load 'rustic
  (define-key rustic-mode-map (kbd "C-c C-b") #'rustic-cargo-build)
  (define-key rustic-mode-map (kbd "C-c C-r") #'rustic-cargo-run)
  (define-key rustic-mode-map (kbd "C-c C-t") #'rustic-cargo-test)
  (define-key rustic-mode-map (kbd "C-c C-c") #'rustic-cargo-current-test)
  (define-key rustic-mode-map (kbd "C-c C-k") #'rustic-cargo-check)
  (define-key rustic-mode-map (kbd "C-c C-l") #'rustic-cargo-clippy)
  (define-key rustic-mode-map (kbd "C-c C-d") #'rustic-cargo-doc)
  (define-key rustic-mode-map (kbd "C-c C-a") #'rustic-cargo-add)
  (define-key rustic-mode-map (kbd "C-c C-f") #'rustic-format-buffer)
  (define-key rustic-mode-map (kbd "C-c C-m") #'lsp-rust-analyzer-expand-macro))

(add-hook 'rustic-mode-hook
          (lambda ()
            (lsp-deferred)
            (setq-local fill-column 100)))

;; -----------------------------------------------------------------------------
;; Cargo minor mode
;; -----------------------------------------------------------------------------
(require 'cargo)

(add-hook 'rustic-mode-hook #'cargo-minor-mode)

;; (with-eval-after-load 'cargo
;;   (define-key cargo-minor-mode-map (kbd "C-c C-v b") #'cargo-process-build)
;;   (define-key cargo-minor-mode-map (kbd "C-c C-v r") #'cargo-process-run)
;;   (define-key cargo-minor-mode-map (kbd "C-c C-v t") #'cargo-process-test)
;;   (define-key cargo-minor-mode-map (kbd "C-c C-v c") #'cargo-process-check)
;;   (define-key cargo-minor-mode-map (kbd "C-c C-v C") #'cargo-process-clean)
;;   (define-key cargo-minor-mode-map (kbd "C-c C-v d") #'cargo-process-doc)
;;   (define-key cargo-minor-mode-map (kbd "C-c C-v D") #'cargo-process-doc-open)
;;   (define-key cargo-minor-mode-map (kbd "C-c C-v u") #'cargo-process-update)
;;   (define-key cargo-minor-mode-map (kbd "C-c C-v e") #'cargo-process-run-example))

;; -----------------------------------------------------------------------------
;; Flycheck
;; -----------------------------------------------------------------------------
(require 'flycheck)
(require 'flycheck-rust)

(setq flycheck-check-syntax-automatically '(save mode-enabled)
      flycheck-indication-mode            'left-fringe)

(add-hook 'rustic-mode-hook #'flycheck-mode)
(add-hook 'flycheck-mode-hook #'flycheck-rust-setup)

(with-eval-after-load 'flycheck
  (define-key flycheck-mode-map (kbd "C-c ! n") #'flycheck-next-error)
  (define-key flycheck-mode-map (kbd "C-c ! p") #'flycheck-previous-error)
  (define-key flycheck-mode-map (kbd "C-c ! l") #'flycheck-list-errors))

;; -----------------------------------------------------------------------------
;; Completion
;; -----------------------------------------------------------------------------

(require 'company)

(setq company-minimum-prefix-length     1
      company-idle-delay                0.2
      company-tooltip-align-annotations t)

(add-hook 'rustic-mode-hook #'company-mode)

(with-eval-after-load 'company
  (define-key company-active-map (kbd "C-n")   #'company-select-next)
  (define-key company-active-map (kbd "C-p")   #'company-select-previous)
  (define-key company-active-map (kbd "<tab>") #'company-complete-selection))

;; -----------------------------------------------------------------------------
;; Snippets
;; -----------------------------------------------------------------------------
;; (require 'yasnippet)
;; (require 'yasnippet-snippets)

;; (add-hook 'rustic-mode-hook #'yas-minor-mode)
;; (yas-reload-all)

;; -----------------------------------------------------------------------------
;; Project navigation
;; -----------------------------------------------------------------------------
(require 'projectile)

(projectile-mode +1)
(define-key projectile-mode-map (kbd "C-c p") #'projectile-command-map)

;; -----------------------------------------------------------------------------
;; Tree-sitter (Emacs 29+ only — remove block if on 28 or below)
;; -----------------------------------------------------------------------------
(when (and (fboundp 'treesit-available-p) (treesit-available-p))
  (add-hook 'rust-ts-mode-hook
            (lambda ()
              (lsp-deferred)
              (setq-local fill-column 100))))

;; -----------------------------------------------------------------------------
;; Keybinding reference (C-c prefix summary)
;; -----------------------------------------------------------------------------
;;
;; LSP (C-c l)
;;   C-c l r   Rename symbol
;;   C-c l a   Code action
;;   C-c l d   Go to definition
;;   C-c l R   Find references
;;   C-c l i   Find implementation
;;   C-c l h   Hover docs
;;   C-c l f   Format buffer
;;   C-c l u   Toggle lsp-ui-doc popup
;;
;; Rustic (C-c C-)
;;   C-c C-b   cargo build
;;   C-c C-r   cargo run
;;   C-c C-t   cargo test (all)
;;   C-c C-c   cargo test (current fn)
;;   C-c C-k   cargo check
;;   C-c C-l   cargo clippy
;;   C-c C-d   cargo doc
;;   C-c C-f   rustfmt buffer
;;   C-c C-m   Expand macro at point
;;
;; Cargo minor mode (C-c C-v)
;;   C-c C-v b   cargo build
;;   C-c C-v r   cargo run
;;   C-c C-v t   cargo test
;;   C-c C-v c   cargo check
;;   C-c C-v C   cargo clean
;;   C-c C-v d   cargo doc
;;   C-c C-v u   cargo update
;;   C-c C-v e   cargo run --example
;;
;; Flycheck (C-c !)
;;   C-c ! n   Next error
;;   C-c ! p   Previous error
;;   C-c ! l   Error list
;;
;; Navigation
;;   M-.   Peek definition
;;   M-?   Peek references
