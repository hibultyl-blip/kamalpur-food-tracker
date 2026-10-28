[app]
title = Kamalpur Food Tracker
package.name = kamalpurfoodtracker
package.domain = in.sandipanfoody
source.dir = .
source.include_exts = py,kv,png,jpg,jpeg,atlas
version = 0.1
requirements = python3,kivy
orientation = portrait
fullscreen = 0

android.permissions = INTERNET
android.api = 35
android.minapi = 23
android.archs = arm64-v8a, armeabi-v7a
android.accept_sdk_license = True

[buildozer]
log_level = 2
warn_on_root = 1
