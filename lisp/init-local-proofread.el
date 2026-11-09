;;; init-local-proofread.el --- Context-aware LLM proofreading -*- lexical-binding: t -*-
;;; Commentary:

;; This module holds the machinery only.  The endpoint that serves the model is
;; private, so its coordinates live in `init-local-proofread-config.el', which
;; is gitignored.  To enable proofreading on a new machine, copy
;; `init-local-proofread-config.el.template' to that name and fill it in.
;;
;; Without that file the module defines its variables and stops: it touches no
;; `load-path', installs no package, and leaves `proofread-profiles' alone.

;;; Code:

(require 'auth-source)

(defvar my/proofread-checker-name 'default
  "Symbol that identifies the checker inside proofread.")

(defvar my/proofread-endpoint-url nil
  "Base URL of the OpenAI-compatible endpoint, with a trailing slash.
`llm' appends the command itself, so this stops before the command:
use \"https://example.test/v1/\", not \".../v1/chat/completions\".")

(defvar my/proofread-auth-host nil
  "Value of the `:host' field that carries the API key in ~/.authinfo.")

(defvar my/proofread-auth-user "apikey"
  "Value of the `:user' field that carries the API key in ~/.authinfo.")

(defvar my/proofread-chat-model nil
  "Name of the model to request from `my/proofread-endpoint-url'.")

(defvar my/proofread-provider-identity nil
  "Provider identity string recorded on each proofread result.")

(defvar my/proofread-source-label nil
  "Human-readable label shown for results from this checker.")

(defvar my/proofread-chat-params nil
  "Alist of non-standard chat parameters to send with every request.
Only a model that needs a special route or reasoning effort sets this;
leave nil for a model that takes the standard chat parameters.")

(defvar my/proofread-model-metadata nil
  "Plist of `llm-models-add' arguments to register the configured model.
Set this only when `llm' does not already know `my/proofread-chat-model';
leave nil when the model is already registered upstream.")

(require 'init-local-proofread-config nil t)

(defun my/proofread--ensure-model-metadata ()
  "Register `my/proofread-model-metadata' when `llm' does not know the model."
  (when (and my/proofread-model-metadata
             (not (llm-models-match my/proofread-chat-model)))
    (apply #'llm-models-add my/proofread-model-metadata)))

(defun my/proofread--provider (model params)
  "Build an `llm' provider that reaches MODEL over the private endpoint.
PARAMS is an alist of non-standard chat parameters; see
`my/proofread-chat-params'."
  (make-llm-openai-compatible
   :url my/proofread-endpoint-url
   ;; llm resolves a function-valued `:key' at request time, so ~/.authinfo is
   ;; read on first check and the secret never lands in the provider struct.
   :key (lambda ()
          (auth-source-pick-first-password
           :host my/proofread-auth-host
           :user my/proofread-auth-user))
   :chat-model model
   :default-chat-non-standard-params params))

(defun my/proofread--checker ()
  "Build the proofread checker from the private endpoint settings."
  `( :name ,my/proofread-checker-name
     :backend llm
     :options ( :provider ,(my/proofread--provider
                            my/proofread-chat-model
                            my/proofread-chat-params)
                :provider-identity ,my/proofread-provider-identity
                :source-label ,my/proofread-source-label
                :response-strategy auto
                :diagnostic-passes 1)))

;; Everything below is optional tooling, so nothing is loaded or installed
;; until the private config proves there is an endpoint to talk to.
(when (and my/proofread-endpoint-url my/proofread-chat-model)
  ;; Proofread is registered in lisp/package-list.el, but async-installer only
  ;; extends `load-path' during install postprocess, so — as with anvil — the
  ;; directory has to be re-added on every startup.
  (let ((proofread-dir (expand-file-name
                        "external-packages/emacs-proofread/lisp/proofread"
                        user-emacs-directory)))
    (when (file-directory-p proofread-dir)
      (add-to-list 'load-path proofread-dir)))

  ;; `maybe-require-package' downgrades an install failure to a warning, and
  ;; the clone is asynchronous on a fresh machine, so tolerate proofread being
  ;; absent on the very first startup after registration.
  (when (and (maybe-require-package 'llm)
             (require 'llm-openai nil t)
             (require 'proofread nil t))
    (my/proofread--ensure-model-metadata)
    (setq proofread-profiles
          `((english . ( :language "en"
                         :display-language "English"
                         :checkers (,(my/proofread--checker))))))
    (setq proofread-profile 'english))

  ;; C-c g p (my/llm-proof) exists only when llm loaded.
  (unless (featurep 'llm)
    (display-warning 'init-local-proofread "llm missing: C-c g p is dead")))

(provide 'init-local-proofread)
;;; init-local-proofread.el ends here
