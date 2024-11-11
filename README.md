# Bambu Lab Stream Automation

## Description

This project uses the **Bambu Lab** integration in **Home Assistant** to monitor your Bambu Lab 3D printer and automatically start a livestream using **OBS**. It monitors the printer's status and runs a **.bat** file on a machine running Windows to start a **go2rtc** server and launch **OBS**.

## Why

I wanted a way to monitor my print while at work. I could have used the Bambu Handy app, but didn't want to drain my phone's battery or make it look like I was on my phone all day. With this, I can pull up the Twitch stream on my work laptop and watch it that way.

## Setup

### Prerequisites

1. **[Home Assistant](https://www.home-assistant.io/)**:
     - [Advanced SSH and Web Terminal](https://github.com/hassio-addons/addon-ssh) or [Studio Code Server](https://github.com/hassio-addons/addon-vscode) (We just need a terminal on Home Assistant)
     - [HACS](https://www.hacs.xyz/) to install custom integrations
     - [Bambu Lab Integration](https://github.com/AdrianGarside/ha-bambulab)
     - [Shell Command Integration](https://www.home-assistant.io/integrations/shell_command)
3. **[Bambu Lab Printer](https://bambulab.com/en-us)**. Bambu Lab X1 Carbon and A1/A1 Mini should work, not sure about P1P/S.
4. **[OBS Studio](https://obsproject.com/)** or any other livestreaming software that supports web sources.
5. **[go2rtc](https://github.com/AlexxIT/go2rtc)**.
6. A machine with an SSH server and to host the live stream and go2rtc server.

### Installation
#### Setting up **go2rtc**
1. Download the latest version of **[go2rtc](https://github.com/AlexxIT/go2rtc)** and put it somewhere safe. I put mine in `C:\Users\USERNAME\Documents\PrinterStream`.
2. In the same directory as **go2rtc**, you'll want to create a file called `go2rtc.yaml`(or copy the default from the repo and remove the `.DEFAULT` extension).
3. Now go to your printer. You'll need to activate **LAN Mode Liveview** (Toggle the switch in section 3 to **ON**) and take note of your **Access Code** (Section 2):
   
     ![20240918-161124](https://github.com/user-attachments/assets/c4127b9e-92ee-4bc6-ac0b-4e34bda285ae)

5. Open `go2rtc.yaml` and change the `PRINTER_IP_ADDRESS` and `ACCESS_CODE` to your printer's IP address. Your file should look something like this:
   ```bash
   streams:
     bambu: rtsps://bblp:ACCESS_CODE@PRINTER_IP_ADDRESS:322/streaming/live/1
   ```
6. Save the file and run **go2rtc.exe** to start the server. You can check that it is working by going to and check that `bambu` shows in the list. Check the box and click **stream**:
   ```bash
   http://localhost:1984
   ```
      ![image](https://github.com/user-attachments/assets/2eb3904e-3136-4800-9ad6-74650cbaf8bc)
  
7. You can also go directly to the `bambu` stream by going to:
   ```bash
   http://localhost:1984/stream.html?src=bambu&mode=webrtc
   ```
8. If everything worked, you should now see a stream of your printer's camera in the brower:
   ![image](https://github.com/user-attachments/assets/830604a3-8f5a-4ef4-9b4a-b936a2bac8e0)

#### Setting up OBS stream
1. Download the latest version of **[OBS Studio](https://obsproject.com/)** or any other broadcasting software and follow the installation guides.
2. Add a new **VLC Video Source** to your scene and configure it as so:
![image](https://github.com/user-attachments/assets/eaea4ccd-22a5-40c3-a5da-ab07f736edda)

     URL:
     ```bash
     rtsp://localhost:8554/bambu
     ```
3. Now your OBS should have the Printer's camera as a source!

#### Setting up Scheduled Task to launch **go2rtc** and **OBS**
This section will vary depending on what machine you are using to host **OBS** and **go2rtc**, but this is what worked best for me. At first, I thought about launching the `start_stream.bat` through an SSH command from Home Assistant but the issue with that is that **go2rtc** and **OBS** would be launched as a service, which doesn't work with **OBS**. I stumbled upon this solution here: [Open Windows application via SSH](https://www.reddit.com/r/SiriShortcuts/comments/9h3w36/open_windows_application_via_ssh/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button). In the event that the post gets deleted, this is what it said:

  ***First things first, you need to setup a SSH server on windows. For this, I used the inbuilt one that can be installed by going to: Apps and Features (in settings)>Manage optional features>Add feature>OpenSSH Server.***

  ***Then, you need to use Task Scheduler to create a 'basic task' (right hand menu). Specify this to run 'One Time' in the past so that it will never realistically run without being triggered. Select start program and select the program of your choice. I'm currently using a .vbs script which opens all the programs I need so I don't need multiple tasks. You could use that or something similar like a .bat script but either way there's plenty of tutorials online on how to open programs with them.***

  ***Once you've entered the SSH info in Siri Shortcuts (ip, port, user, pass) the script you'll need to run is:***

  ***`schtasks /run /i /TN <task name>`***

We aren't gonna need the last part about the Siri Shortcuts so we can ignore that. The program you will want to start is `start_stream.bat` and I named my task `Start Printer Stream`

If more clarification is needed, follow these steps:
- [Installing OpenSSH on Windows 10](https://winscp.net/eng/docs/guide_windows_openssh_server)
- [Creating a Scheduled Task on Windows](https://www.windowscentral.com/how-create-automated-task-using-task-scheduler-windows-10)

#### Configuring Home Assistant
1. I'll be assuming you have the [Bambu Lab Integration](https://github.com/AdrianGarside/ha-bambulab) setup and have your printer added.
2. The most important thing that you'll need to do is creating a Key Pair for SSH. This is necessary as SSH commands ran from Home Assistant aren't interactive, so a password can't be provided (and we don't want to manually enter it anyways).
3. At this point, you can set up [Advanced SSH and Web Terminal](https://github.com/hassio-addons/addon-ssh) using this guide: [Home Assistant - Advanced SSH and Web Terminal Installation and Configuration - Step by Step Guide.](https://www.youtube.com/watch?app=desktop&v=fw69Tf9F5DU) or you can use the provided terminal in [Studio Code Server](https://github.com/hassio-addons/addon-vscode).
4. You should already be in the `/config` directory, but if not, navigate there.
5. Run this command:
   
   ```bash
   ssh-keygen -t rsa -b 4096
   ```
   
6. When prompted `Enter file in which to save the key (/root/.ssh/id_rsa):` enter this:
   
   ```bash
   /config/.ssh/id_rsa
   ```
   
7. The reason for this is that files in `/root` can be deleted on updates and inaccessible by certain add-ons. Just press enter until it creates the file since we don't need a passphrase.
8. Now enter this command to display the public key:

    ```bash
    cat /config/.ssh/id_rsa.pub
    ```

9. The outputted key should be in the format `ssh-rsa ... root@XXXXXXX-ssh`. Copy this key.
10. This key will need to be added to our Windows machine's `authorized_keys` or `administrators_authorized_keys` file.

     If the user you are using to host OBS **isn't** an **Administrator**, you will add the key to the `authorized_keys` file at `C:\Users\USERNAME\.ssh\` or create the files\folders if they don't exist.

     If the user you are using to host OBS **is** an **Administrator**, you will add the key to the `administrators_authorized_keys` file at `C:\ProgramData\ssh` or create the files\folders if they don't exist.

11. This part is ***IMPORTANT!!*** In Windows, you need to have ***very*** specific permissions to those files in order for them to work properly. The easiest way to get the correct permission is to run this command in a **Administrator** Powershell:

    **For Non-administrators:**
    ```bash
    icacls.exe "`C:\Users\USERNAME\.ssh\authorized_keys" /inheritance:r /grant "USERNAME:F" /grant "SYSTEM:F"
    ```
    **For Administrators:**
    ```bash
    icacls.exe "C:\ProgramData\ssh\administrators_authorized_keys" /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"
    ```

    Anytime you need to add another key to those files, make sure to re-run that command to correct the permissions.

12. You also might need to update `sshd_config` to allow Public Key Authentication. Navigate to `C:\ProgramData\ssh` and open `sshd_config`. Verify that `PubkeyAuthentication yes` is not commented out. If changes were made to the file, you will have to restart the SSH server, which can be done by running this Powershell command:

    ```bash
    Restart-Service sshd
    ```

13. Now back in the terminal for [Studio Code Server](https://github.com/hassio-addons/addon-vscode), you want to try to SSH into the remote machine using the private key. If successful, you won't need to enter a password to connect. To do so, you will want to use this command:

    ```bash
    ssh -i /config/.ssh/id_rsa USERNAME@IP_ADDRESS
    ```

    `USERNAME`: Remote machine username
    
    `IP_ADDRESS`: IP Address of the remote machine

14. Once the keypairs for SSH are setup, you will create a shell command in `configuration.yml` that we will use in our automation. Here is an example of what you'll add to `configuration.yml`:

    ```bash
    shell_command:
      start_printer_stream: 'ssh USERNAME@IP_ADDRESS -i /config/.ssh/id_rsa -t ''cmd /c schtasks /run /i /TN "SCHEDULED_TASK_NAME"'''
    ```

    `USERNAME`: Remote machine username
  
    `IP_ADDRESS`: IP Address of the remote machine

    `SCHEDULED_TASK_NAME`: The name of the scheduled task created earlier.

15. Restart **Home Assistant** after the changes to `configuration.yml`. Then, you'll want to create an **Automation** to run the script. You can switch to **Edit in YAML** mode to copy the below configuration in:

     ```bash
     alias: Start X1C Stream
     description: When the printer starts printing, send an SSH command.
     triggers:
       - trigger: state
         entity_id:
           - sensor.YOUR_PRINTER_print_status
         from: idle
         to: prepare
     conditions: []
     actions:
       - action: shell_command.start_printer_stream
         metadata: {}
         data: {}
     mode: single
     ```

     `YOUR_PRINTER`: The entity ID of your printer

16. Switch back to **Edit in Visual Editor** and click the 3 dots and then **run** the shell command to test that it works. If it does, then you have everyting setup! You now have Home Assistant configured to send an SSH command to a remote machine to start a stream!
