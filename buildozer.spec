[app]
icon.filename = %(source.dir)s/icon.png
presplash.filename = %(source.dir)s/icon.png
title = Kamalpur Food Tracker
package.name = kamalpurfoodtracker
package.domain = in.sandipanfoody
source.dir = .
source.include_exts = py,kv,png,jpg,jpeg,atlas
version = 0.1
requirements = python3,kivy==2.3.0
orientation = portrait
fullscreen = 0

android.permissions = INTERNET
android.api = 33
android.minapi = 23
android.archs = arm64-v8a
android.accept_sdk_license = True
android.ndk = 25b

[buildozer]
log_level = 2
warn_on_root = 1
