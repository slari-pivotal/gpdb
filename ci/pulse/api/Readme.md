Pulse for Checkman
==================

Monitor your pulse builds in checkman.

Usage
-----

You need to have a few things before we start:

* The url of your pulse instance. Ex: ```https://pulse.pivotal.io``` No trailing slash.
* The name of the project you want to monitor.
* Your username.
* Your password.

Clone the repository somewhere to keep:

```
git clone https://github.com/Pivotal-DataFabric/pulse-checkman.git
```

Add the following to your checkman config file (often found in ~/Checkman/):

```
name you want displayed: /path/to/your/checkout/bin/pulse_checkman YOUR_URL YOUR_PROJECT_NAME
```

Also, you need to make sure that your username and password are set to the correct environment variables, PULSE_CHECKMAN_USERNAME and PULSE_CHECKMAN_PASSWORD respectively.
The easiest way to do that is to add the following to the beginning of the script in the config file:

```
name you want displayed: PULSE_CHECKMAN_USERNAME=admin PULSE_CHECKMAN_PASSWORD=password /path/to/your/checkout/bin/pulse_checkman YOUR_URL YOUR_PROJECT_NAME
```

So, for example, if I had a project named "Test HAWQ" and my pulse was located at https://pulse.pivotal.io, then I would add the following to my checkman config:

```
HAWQ tests: PULSE_CHECKMAN_USERNAME=pulse_checkman PULSE_CHECKMAN_PASSWORD=souper_secret /usr/lib/pulse_checkman/bin/pulse_checkman https://pulse.pivotal.io "Test HAWQ"
```
