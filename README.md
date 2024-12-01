# Git repositories multi download sctript

About: It is used for simultaneously downloading selected repositories or all repositories of a specific GitHub user.

## Ubuntu:

1  Install `curl` и `jq` (utils for JSON)
```bash
sudo apt-get install curl jq
```

2 Make script executable:
```bash
chmod +x gitmulti.sh
```

3 Install Git if it absent:
```bash
sudo apt update
sudo apt install git -y
```

4 Run execute command:
```bash
./gitmulti.sh username my_personal_access_token
```