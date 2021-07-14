[<img title="Monash University" src="https://www.monash.edu/__data/assets/file/0015/2521311/60YearsStamp_MonashLogo_MONO_WEB.svg" height="auto" width="256">](https://www.monash.edu/blockchain)    **&**
[<img title="Algorand Technologies" src="https://www.algorand.com/assets/media-kit/logos/full/png/algorand_full_logo_black.png" height="auto" width="200">](https://algorand.com)


# Monash University Bloackchain Hackathon 2021
This repository contains the code, content and demo material for participation of [@emg110](https://github.com/emg110) and [@sheghzo](https://github.com/sheghzo) in Monash Blockchain Hackathon 2021.

## Usefull links

> [Monash University](https://www.monash.edu)

> [Monash University Blockchain Departement](https://www.monash.edu/blockchain)

> [Algorand](https://www.algorand.com/)

> [Sensor Emulator](https://github.com/emg110/sensor-emulator)

## Technical notes

> Run `./desense.sh help` to see available flows and commands

> Run `./desense.sh install` first , then  `./desense.sh startsandbox`, then  `./desense.sh startemitter` and finally, then  `./desense.sh start emulator` as order of running things but read forward through technical notes first!

> It'srecommended to run emitter and emulator in different bash terminals than main one, for they have continius logging of published and received sensor data which may interfere with user experience!

> When running `./desense.sh startemitter` for the first time you will be given just generated a license and a secret code for a new registered sensor netwrok on your localhost.
![The license and secret key to generated Sensor Network](./assets/sns-license-scrshot.png)
Take note of these two and set EMITTER_LICENSE environment variable:

`export EMITTER_LICENSE="PfA8IHtI_zkp1tEGEG3T86--Gy6bexPlMVxzi3o4_aEMGBCfEK7GTYaxmK6Zche0DLQfMDamuYnxC9XB9p8BAQ:3"`

Open your browser and go to Sensor Network registeration panel `http://127.0.0.1:8080/keygen` and register your channel name `/desense` to get a channel key.

![Web based SNS channel generator & key registeration](./assets/sns-keyreg-scrshot.png)

Use the channel key you just received from keygen and set it in key configuration of your sensor emulator `sensor-template-config.json`. Along with channel key set the port of your sensor network e.g 8080 and also paste the sensor network license mentioned above into the license configuration. Make sure you do these configurations before starting emulator with `./desense startemulator` command.

![The sensor emulator configuration](./assets/sensor-emulator-config-scrshot.png)

> If the setup is OK then by starting sensor emulator via `./desense startemulator` this should be the output:

![The sensor emulator running...](./assets/startemulator.png)

## Design Info

> ![deSense Concept](./assets/deSense%20Concept.png)

> ![deSense Sequences](./assets/deSense%20Sequences.png)

> ![deSense UseCase Diagram](./assets/deSense%20UseCase.png)

## Presentation Poster

> ![deSense Presentation Poster](./assets/dSense%20Presentation%20Poster.png)

## Presentation Video

> [![deSense Presentation Video](./assets/desense-dashboard.png)](./assets/dSense-video-presentation.webm)

## Sensor Emulator Screen Cast

> ![Senor Emulator Screencast Telesensing to Algorand blockchain and gives Transaction ID out](./assets/sensor_emulator.gif)

## Based on amazing libraries and examples of

> [EmitterIO](https://github.com/emitter-io/emitter)

> [Sampler](https://github.com/sqshq/sampler)

> [mqtt-emulator](https://github.com/dojot/mqtt-emulator)-----> Forked and extensively modified & overhauled version created just for this Hackathon [sensor-emulator](https://github.com/emg110/sensor-emulator)
