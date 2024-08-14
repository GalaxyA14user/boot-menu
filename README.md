# boot-menu
A Simple magisk module that shows a boot menu before the OS starts. Easily customizable. Currently supports OneUI ext4 filesystems only. Experimental.

# How does it work
Read the code to know.

# Customize
There exists display.so, open it with text editor to modify the start and end of where the button is, alongside the index order. Touches are converted to a 1000 by 1000 plane (stretches) for the codes to work on all devices better. Check /cache/boot-menu/boot-menu.log to know more about how touches and volume buttons are handled. SP is the splash which appears before F${index} (F0, F1, F2...) and those are displayed when the index is met (default 1). The timeout is 10 seconds by default before defaulting index 1.

# Notice
Confirmed working on Galaxy A145F & Galaxy note 10
Telegram: @GalaxyA14user
