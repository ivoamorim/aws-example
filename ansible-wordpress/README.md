Ansible-WordPress
=========

Simple tutorial provision EC2 instance and deploying wordpress to it with Ansible.

Requirements
------------

- ansible
- boto
- botocore
- boto3


How To Use
------------
Install Dependencies.
```
pip install -r requirements.txt
```

Add AWS credentials to enable access with boto.
```
$ aws configure
AWS Access Key ID [None]: XXXXX
AWS Secret Access Key [None]: XXXXX
Default region name [None]: us-east-1
Default output format [None]: json
```

Edit KeyPair Information.
```
# ansible.cfg
private_key_file=/path/to/KeyPair.pem -> Set proper key path

# group_vars/all.yml
my_vars:
  ec2:
    key_name: XXXXX -> Set KeyPairName on AWS EC2 console website
```

Execute playbook to develop AWS environment.
```
ansible-playbook -i localhost site.yml -v
```

Get and Add RDS Endpoint.
```
$ aws rds describe-db-instances --query="DBInstances[].Endpoint"

# group_vars/all.yml
my_vars:
  rds:
    endpoint: XXXXX -> Set RDS Endpoint
```

Execute playbook.
```
$ ansible-playbook site.yml -v
```

Access WordPress.
```
http://EC2-instance-IP/wordpress/wp-admin/setup-config.php
```
- DBName：wordpress
- User：wordpress-user
- Password：wordpress

References
------------
- https://qiita.com/rednes/items/2963bc367d7d84db81a0
- https://qiita.com/katsuhiko/items/5c73781bf2f4f2aeabef
- https://github.com/rednes/ansible-aws-sample
- https://docs.ansible.com/ansible/latest/user_guide/intro_dynamic_inventory.html#inventory-script-example-aws-ec2
