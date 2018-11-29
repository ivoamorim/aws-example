EC2-Apache
=========

Simple tutorial deploying httpd to EC2 instance.

Requirements
------------

- jq

How To Use
------------
Edit inventory file
```
X.X.X.X -> EC2 instance's IP address or hostname
ansible_ssh_private_key_file=/path/to/keypair.pem -> Change proper KeyPair.pem path
```
Setup AWS
```
bash setup.sh
```
Execute ansible-playbook
```
ansible-playbook -i inventory playbook.yml
```

References
------------
- https://qiita.com/hiroshik1985/items/9de2dd02c9c2f6911f3b
- https://qiita.com/yarakaki/items/48e1245193ef7a942a7e
- https://qiita.com/tcsh/items/41e1aa3c77c469c92e84
