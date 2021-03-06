#|

Copyright (C) 2012-2015 Christian Stigen Larsen
http://csl.name

Distributed under the LGPL 2.1; see LICENSE

|#

(define-library (mickey library)
  (import (posix dlopen))

  (export
    bind-procedure
    bind-syntax
    current-handle
    open-internal-library
    open-internal-library-determine-extension
    open-library
    open-self)

  (begin

    ;; First we'll do a dirty trick to get cons and friends locally
    ;; We'll load the scheme-base file directly and bind procedures
    ;;
    ;; Many of the core scheme stuff is found statically in eval(),
    ;; so we don't need to do anything about those yet.

    (define base
      (dlopen-internal-determine-extension "libscheme-base" 'lazy 'global))

    (define cons          (dlsym base "proc_cons"))
    (define error         (dlsym base "proc_error"))
    (define not           (dlsym base "proc_not"))
    (define string-append (dlsym base "proc_strcat"))
    (define let    (dlsym-syntax base "proc_let"))

    ;; Some local variables and accessors
    ;;
    (define *handle* #f)
    (define *file*   #f)

    (define (current-handle) *handle*)
    (define (current-file)   *file*)

    ;; Usage: (open-library file . options) where `options` are the same as
    ;; for (dlopen) in (posix dlopen).
    ;;
    (define (open-library filename . options)
      (set! *file* filename)
      (set! *handle* (apply dlopen (cons *file* options)))

      (if (not *handle*)
        (error (string-append
          "Could not dlopen " *file* ": " (dlerror)))))

    ;; Usage: (open-self . options) where `options` are the same as
    ;; for (dlopen) in (posix dlopen).
    ;;
    (define (open-self . options)
      (set! *file* "")
      (set! *handle* (apply dlopen-self options))

      (if (not *handle*)
        (error (string-append
          "Could not dlopen-self: " (dlerror)))))

    ;; Same as open-library above, but opens file from Mickey Scheme's
    ;; library location.
    ;;
    (define (open-internal-library filename . options)
      (set! *file* filename)
      (set! *handle* (apply dlopen-internal (cons *file* options)))

      (if (not *handle*)
        (error (string-append
          "Could not dlopen " *file* ": " (dlerror)))))

    ;; Same as open-internal-library but automatically adds proper dynamic
    ;; library extension per platform.
    (define (open-internal-library-determine-extension basename . options)
      (set! *file* basename)
      (set! *handle* (apply dlopen-internal-determine-extension
                        (cons *file* options)))
      (if (not *handle*)
        (error (string-append
          "Could not dlopen " *file* ": " (dlerror)))))

    ;; Usage: (bind-procedure "some_c_function")
    ;;
    ;; Returns closure of function in library.
    ;;
    (define (bind-procedure name)
      (let
        ((r (dlsym *handle* name)))
        (if (not r)
          (error (string-append
            "Could not dlsym " name " in " *file* ": "
            (dlerror))))
        r))

    ;; Usage: (bind-syntax "some_c_function")
    ;;
    ;; Returns syntactic closure of function in library.
    ;;
    (define (bind-syntax name)
      (let
        ((r (dlsym-syntax *handle* name)))
        (if (not r)
          (error (string-append
            "Could not dlsym " name " in " *file* ": "
            (dlerror))))
        r))
