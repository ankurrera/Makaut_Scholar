# Makaut Scholar – Dev Shortcuts
# Usage: make run   /  make build  /  make apk

.PHONY: run build apk

run:
	flutter run --dart-define-from-file=.env

build:
	flutter build appbundle --dart-define-from-file=.env

apk:
	flutter build apk --dart-define-from-file=.env

clean:
	flutter clean
	flutter pub get
