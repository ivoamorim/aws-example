#!/bin/bash -x
# Init
PROJECT_NAME='tutorial'

#####
# create VPC
#####
VPC_NAME="VPC-${PROJECT_NAME}"
VPC_ADDR='10.0.0.0/16'

aws ec2 create-vpc --cidr-block ${VPC_ADDR}
VPC_ID=`aws ec2 describe-vpcs --filters "Name=cidr,Values=${VPC_ADDR}" --query 'Vpcs[].VpcId' --output text` && echo ${VPC_ID}
aws ec2 create-tags --resources ${VPC_ID} --tags Key=Name,Value=${VPC_NAME}

## VPC Subnet
VPC_SUBNET01_NAME="VPC-ZoneA-${PROJECT_NAME}"
VPC_NET01_AZ='us-east-1a'
VPC_SUBNET01='10.0.0.0/24'
VPC_SUBNET02_NAME="VPC-ZoneB-${PROJECT_NAME}"
VPC_NET02_AZ='us-east-1b'
VPC_SUBNET02='10.0.1.0/24'

aws ec2 create-subnet --vpc-id ${VPC_ID} --availability-zone ${VPC_NET01_AZ} --cidr-block ${VPC_SUBNET01}
VPC_SUBNET01_ID=`aws ec2 describe-subnets --filters Name=cidrBlock,Values=${VPC_SUBNET01} --query 'Subnets[].SubnetId' --output text` && echo ${VPC_SUBNET01_ID}
aws ec2 create-tags --resources ${VPC_SUBNET01_ID} --tags Key=Name,Value=${VPC_SUBNET01_NAME}

aws ec2 create-subnet --vpc-id ${VPC_ID} --availability-zone ${VPC_NET02_AZ} --cidr-block ${VPC_SUBNET02}
VPC_SUBNET02_ID=`aws ec2 describe-subnets --filters Name=cidrBlock,Values=${VPC_SUBNET02} --query 'Subnets[].SubnetId' --output text` && echo ${VPC_SUBNET02_ID}
aws ec2 create-tags --resources ${VPC_SUBNET02_ID} --tags Key=Name,Value=${VPC_SUBNET02_NAME}

## VPC Internet Gateway
VPC_IGW_NAME="VPC-IGW-${PROJECT_NAME}"
aws ec2 create-internet-gateway
VPC_IGW_ID=`aws ec2 describe-internet-gateways | jq -r '.InternetGateways[] | select(.Attachments == []).InternetGatewayId'` && echo ${VPC_IGW_ID}
aws ec2 attach-internet-gateway --internet-gateway-id ${VPC_IGW_ID} --vpc-id ${VPC_ID}
aws ec2 create-tags --resources ${VPC_IGW_ID} --tags Key=Name,Value=${VPC_IGW_NAME}
aws ec2 describe-internet-gateways --internet-gateway-ids ${VPC_IGW_ID}

## VPC Routes Table
VPC_RT_NAME="VPC-RT-${PROJECT_NAME}"

aws ec2 create-route-table --vpc-id ${VPC_ID}
VPC_RT_ID=`aws ec2 describe-route-tables | jq -r '.RouteTables[] | select(.Associations == []) | .RouteTableId'` && echo ${VPC_RT_ID}
aws ec2 create-tags --resources ${VPC_RT_ID} --tags Key=Name,Value=${VPC_RT_NAME}
aws ec2 associate-route-table --route-table-id ${VPC_RT_ID} --subnet-id ${VPC_SUBNET01_ID}
aws ec2 associate-route-table --route-table-id ${VPC_RT_ID} --subnet-id ${VPC_SUBNET02_ID}
aws ec2 create-route --route-table-id ${VPC_RT_ID} --destination-cidr-block 0.0.0.0/0 --gateway-id ${VPC_IGW_ID}

# Security Group
VPC_SG_NAME="VPC-SG-${PROJECT_NAME}"
VPC_SG_DESCRIPT="${PROJECT_NAME} security group"

aws ec2 create-security-group --group-name ${VPC_SG_NAME} --description "${VPC_SG_DESCRIPT}" --vpc-id ${VPC_ID}
VPC_SG_ID=`aws ec2 describe-security-groups --filters Name=group-name,Values=${VPC_SG_NAME} --query 'SecurityGroups[].GroupId' --output text`; echo ${VPC_SG_ID}
aws ec2 create-tags --resources ${VPC_SG_ID} --tags Key=Name,Value=${VPC_SG_NAME}

## Security Group Inbound
VPC_SG_PROTOCOL='tcp'
VPC_SG_PORT='22'
VPC_SG_CIDR='0.0.0.0/0'
aws ec2 authorize-security-group-ingress --group-id ${VPC_SG_ID} \
     --protocol ${VPC_SG_PROTOCOL} --port ${VPC_SG_PORT} \
     --cidr ${VPC_SG_CIDR}

VPC_SG_PROTOCOL='tcp'
VPC_SG_PORT='80'
VPC_SG_CIDR='0.0.0.0/0'
aws ec2 authorize-security-group-ingress --group-id ${VPC_SG_ID} \
     --protocol ${VPC_SG_PROTOCOL} --port ${VPC_SG_PORT} \
     --cidr ${VPC_SG_CIDR}

VPC_SG_PROTOCOL='tcp'
VPC_SG_PORT='443'
VPC_SG_CIDR='0.0.0.0/0'
aws ec2 authorize-security-group-ingress --group-id ${VPC_SG_ID} \
     --protocol ${VPC_SG_PROTOCOL} --port ${VPC_SG_PORT} \
     --cidr ${VPC_SG_CIDR}

aws ec2 describe-security-groups --group-ids ${VPC_SG_ID}

#####
# Create EC2
#####
EC2_INSTANCE_TYPE='t2.micro'
EC2_AMI_DESCRIPTION='Amazon Linux AMI 2018.03.0.20180622 x86_64 HVM GP2'
EC2_AMI_ID=`aws ec2 describe-images --owners amazon --filters Name=description,Values="${EC2_AMI_DESCRIPTION}" --query 'Images[].ImageId' --output text`; echo ${EC2_AMI_ID}

## Create SSH Pair Key
EC2_KEY_NAME="Key-${PROJECT_NAME}"
FILE_SSH_KEY="${HOME}/.ssh/${EC2_KEY_NAME}.pem"

aws ec2 create-key-pair --key-name ${EC2_KEY_NAME} --query 'KeyMaterial' --output text > ${FILE_SSH_KEY}; cat ${FILE_SSH_KEY}
chmod 400 ${FILE_SSH_KEY}
aws ec2 describe-key-pairs --key-name ${EC2_KEY_NAME}

## Create EC2 instance
VPC_SUBNET01_INSTANCES_NAME="Web01-${PROJECT_NAME}"

aws ec2 run-instances \
       --image-id ${EC2_AMI_ID} \
       --instance-type ${EC2_INSTANCE_TYPE} \
       --key-name ${EC2_KEY_NAME} \
       --security-group-ids ${VPC_SG_ID} \
       --subnet-id ${VPC_SUBNET01_ID} \
       --associate-public-ip-address
VPC_SUBNET01_INSTANCES=`aws ec2 describe-instances --filter Name=subnet-id,Values=${VPC_SUBNET01_ID} --query 'Reservations[].Instances[].InstanceId' --output text`; echo ${VPC_NET01_INSTANCES}
aws ec2 create-tags --resources ${VPC_SUBNET01_INSTANCES} --tags Key=Name,Value=${VPC_SUBNET01_INSTANCES_NAME}
VPC_SUBNET01_INSTANCES_ADDR=`aws ec2 describe-instances --instance-id ${VPC_SUBNET01_INSTANCES} --query 'Reservations[].Instances[].PublicIpAddress' --output text`; echo ${VPC_SUBNET01_INSTANCES_ADDR}

# Close
echo "You can connect instance with below command"
echo "ssh -i ${FILE_SSH_KEY} ec2-user@${VPC_SUBNET01_INSTANCES_ADDR}"
