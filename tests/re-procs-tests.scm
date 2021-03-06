(define (test-re-procs)
  (check (regexp? (rx "foo")) => #t)
  (check (regexp? "foo") => #f)

  (check (regexp-search (rx "foo") "bar") => #f)
  (check (regexp-search? (rx "foo") "foo") => #t)
  (check (regexp-search? (rx "bar") "foobar" 3) => #t)
  (check (regexp-search? (rx "bar") "foobar" 4) => #f)
  (check (regexp-search? (rx (: (* numeric))) "123")  => #t)
  (check (regexp-search? (rx (: bos (* numeric))) "123")  => #t)
  (check (regexp-search? (rx (: (* numeric) eos)) "123")  => #t)
  (check (and (regexp-search (rx (: (* numeric))) "123") #t)  => #t)
  (check (and (regexp-search (rx (: bos (* numeric))) "123") #t)  => #t)
  (check (and (regexp-search (rx (: (* numeric) eos)) "123") #t)  => #t)

  (let ((foobarbaz (rx (: (submatch "foo")
                          (submatch "bar")
                          (submatch "baz")))))

    (check (match:start (regexp-search (rx "bar") "foobar")) => 3)
    (check (match:start (regexp-search foobarbaz "foobarbaz") 3) => 6)
    (check (match:start (regexp-search foobarbaz "foobarbaz") 1) => 0)
    (check (match:start (regexp-search foobarbaz "foobarbaz") 4) => #f)
    (check (match:end (regexp-search (rx "fo") "foobar")) => 2)
    (check (match:end (regexp-search foobarbaz "foobarbaz") 2) => 6)
    (check (match:end (regexp-search foobarbaz "foobarbaz") 0) => 9)
    (check (match:end (regexp-search foobarbaz "foobarbaz") 30) => #f)
    (check (match:substring (regexp-search foobarbaz "foobarbaz") 3) => "baz")
    (check (match:substring (regexp-search foobarbaz "foobarbaz") 0) => "foobarbaz")
    (check (match:substring (regexp-search (rx (submatch "foo")) "foo") 2) => #f)

    (check (regexp-substitute #f (regexp-search foobarbaz "foobarbaz")
                              3 2 1) => "bazbarfoo")
    (check (regexp-substitute #f (regexp-search (rx "foo") "!foo!")
                              'pre "bar" 'post) => "!bar!")
    (check (regexp-substitute #f (regexp-search (rx "foo") "foo") "bar") => "bar")
    (check (regexp-substitute #f (regexp-search (rx "foo") "foo")) => "")
    (check (let ((port (open-output-string)))
             (regexp-substitute port (regexp-search foobarbaz "foobarbaz") 2 3 1 "frob")
             (get-output-string port)) => "barbazfoofrob")
    (check (let ((port (open-output-string)))
             (regexp-substitute port (regexp-search (rx "foo") "!foo!")
                               'pre "bar" 'post)
             (get-output-string port)) => "!bar!")
    (check (regexp-substitute/global #f (rx "foo") "foo, foo, foo!"
                                     'pre "bar" 'post) => "bar, bar, bar!")
    (check (regexp-substitute/global #f foobarbaz "foobarbaz" 3 'post) => "baz")
    (check (let ((port (open-output-string)))
             (regexp-substitute/global port (rx "foo") "what the foo!" 'pre 'post)
             (get-output-string port)) => "what the !")

    (check (regexp-fold (rx "foo") (lambda (i m count) (+ count 1))
                        0 "foo, bar, baz, foo, bar") => 2)
    (check (regexp-fold (rx (: "foo" (+ digit)))
                        (lambda (i m list)
                          (cons (match:substring m) list))
                        '() "foo1 foo2 foo3"
                        (lambda (i list) (reverse list))) => '("foo1" "foo2" "foo3"))
    (check (regexp-fold-right (rx (: "foo" (+ digit)))
                              (lambda (m i list)
                                (cons (match:substring m) list))
                              '() "foo1 foo2 foo3"
                              (lambda (i list) (reverse list))) => '("foo3" "foo2" "foo1"))
    (check (let ((foos '()))
             (regexp-for-each (rx "foo")
                              (lambda (m)
                                (set! foos (cons (match:substring m) foos)))
                              "blahblahfooblahblahfoo")
             foos) => '("foo" "foo"))

    (check (let-match (regexp-search foobarbaz "foobarbaz")
                      (fbz foo bar baz)
                      `(,baz ,bar ,foo ,fbz)) => '("baz" "bar" "foo" "foobarbaz"))
    (check (if-match (regexp-search foobarbaz "")
                     (fbz foo bar baz)
                     `(,baz ,bar ,foo ,fbz)
                     'no-match) => 'no-match)
    (check (if-match (regexp-search (rx "bar") "bar")
                     (bar) bar
                     'no-match) => "bar")
    (check (match-cond ((regexp-search foobarbaz "") (fbz foo bar baz) foo)
                       (else 'no-match)) => 'no-match)
    (check (match-cond ((regexp-search foobarbaz "foobarbaz") (fbz foo bar baz) foo)
                       (else 'no-match)) => "foo")

    (check (match:substring (regexp-search (flush-submatches foobarbaz)
                                           "foobarbaz") 1) => #f)
    (check (match:substring (regexp-search (uncase (rx "bar")) "BaR")) => "BaR")
    (check (match:substring (regexp-search (rx ,(uncase-string "blah"))
                                           "Blah")) => "Blah")
    (check (regexp->sre foobarbaz) => '(: (submatch "foo")
                                          (submatch "bar")
                                          (submatch "baz")))
    (check (regexp? (sre->regexp '(: "foobar" "baz"))) => #t)
    (check (regexp-search? (posix-string->regexp "g(ee|oo)se") "goose") => #t)
    (check (receive (string level pcount submatches)
               (regexp->posix-string (rx (: "g" (or "ee" "oo") "se")))
             string) => "g(ee|oo)se")))
