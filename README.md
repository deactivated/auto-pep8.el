# auto-pep8.el - Automatically run pep8.py on save

auto-pep8.el automatically runs PEP8 code style checks on save. It
depends on python-pep8.el.

Usage:

    (require 'auto-pep8)
    (add-hook 'python-mode-hook (lambda () (auto-pep8-mode 1))))
