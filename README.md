# bash-otp
One-Time Password generator for CLI using bash, oathtool.

Automatically copys the token into your computer's copy buffer (MacOS only atm)

This is basically "Authy for the CLI"

This script supports both encrypted and plain-text token files, but my reccomendation is to use encryption.

### Requirements

* oathtool (http://www.nongnu.org/oath-toolkit/)
* OpenSSL
* sshpass

## Description

Set of bash shell scripts to generate OTP *value* from token using TOTP.

## Installation
You should run `setup.sh` to install required tools (Linux)
```
./setup.sh
```

### Usage

0. You should get your "secret"(token) from Non-LBL token management page following this [instruction](http://research-it.berkeley.edu/services/high-performance-computing/using-authy-desktop-computer-generate-one-time-passwords-savio) from step 11 to 19. Please ignore the other steps.
> It should be noted that you don't need to download Authy, getting the secret(token) is enough.

First ensure that there is a directory "tokenfiles" in the main dir where the script resides.
Second ensure that there is a directory "keys" in the main dir where the script resides.

1. Create token file and encrypt it. Resulting file, "tokenfiles/tokenname.enc", is an encrypted file containing the token
  1. Put your secret(token) in a plaintext file in the tokenfiles/ directory:
  ```bash
  $ echo "1234567890abcdef" > tokenfiles/tokenname
  ```
  
  1. Encrypt the file with the included shell script:
  ```bash
  $ ./otp-lockfile.sh tokenfiles/tokenname
  Password: (enter a good password)
  ```
  > You can choose to be lazy but insecure and not encrypt these files so that you don't need to type in the password 
  1. Confirm it worked:
  ```bash
  $ ls tokenfiles/
  tokenname.enc
  ```

  2. You should do the same for your account name and your plain password of your account on the Savio cluster. (Without One Time Passcode)
  store it in "keys/tokenname" in the first two lines like:
  ```
  echo "yourusername" > keys/tokenname
  echo "yourpassword" >> keys/tokenname
  ```
  > It should be noted that the file name of your password can be the same as the token
  If you use different names, password file name needs to be specified after tokenname

3. Run otp.sh; will produce roughly the following output:
  ```
$ ./otp.sh tokenname [passwordname]
Password for secret(token): 

Password for Savio cluster: 
  ```
  
  You might be asked for password if you have encrypted your files.  Otherwise, you should log in to the cluster right away.

# IMPORTANT!
  **Please do NOT frequently log in using this method! You can only use the one time passcode once and it only gets renewed every 30 seconds!**
  **If you log in multiple time with the used one time passcode, your account might be locked!**

## Contents

* Script to do the actual value generation
* Script to encrypt the token in a file
* Script to decrypt same
* Empty "tokenfiles/" directory

