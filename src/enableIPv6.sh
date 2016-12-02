#!/usr/bin/env bash
#
# List out all VPCs in all AWS regions, and enable IPv6 on each. 
#   Also update Route Tables with ::/0 default route and Security Groups to allow IPv6 traffic.
#
#   This script can be expanded out as per one's specific need to take further actions, 
#   like associating IPv6 CIDR blocks with existing subnets. Running this script multiple 
#   times will not harm resources that have already been enabled for IPv6 - conflicting 
#   commands will simply error out.
#
#   Do note that this is built using the OS X install of grep and as such your version 
#   may use alternate flags. Overall it should be compatible with current Linux builds.
#

# Output to both stdout and log-enableIPv6.log, including errors.
exec > >(tee -ia log-enableIPv6.log)
exec 2> >(tee -ia log-enableIPv6.log >&2)

REGIONLIST=( us-east-2 ) # If when running this script you only want to enable some regions, list them here. Otherwise uncomment the line below for all regions.
# REGIONLIST=( us-east-1 us-east-2 us-west-1 us-west-2 ap-south-1 ap-northeast-2 ap-southeast-1 ap-southeast-2 ap-northeast-1 eu-central-1 eu-west-1 sa-east-1 )

for region in "${REGIONLIST[@]}"; do
  # Blank the VPC array for each new region
  VPCLIST=()

  echo "===="
  echo "Checking $region for VPC IDs."

  for vpcid in `aws ec2 describe-vpcs --output json --region $region | grep -ohE "\w*vpc-[a-z0-9]{8}"`; do
    VPCLIST+=("$vpcid")
    echo "$region: $vpcid"
  done

  echo ""

  for vpcid in "${VPCLIST[@]}"; do
    echo "[Enabling IPv6 on $vpcid]"

    echo "Associating IPv6 CIDR Block to $vpcid."
    aws ec2 associate-vpc-cidr-block --output json --region $region --vpc-id $vpcid --amazon-provided-ipv6-cidr-block

    TARGETIGW=$(aws ec2 describe-internet-gateways --output json --region $region | grep -B 10 "$vpcid" | grep -oh "\w*igw-\w*")

    # One IGW per VPC, but many possible Route Tables per VPC.
    for routetable in `aws ec2 describe-route-tables --output json --region $region | grep -B 1 "$vpcid" | grep -oh "\w*rtb-\w*"`; do
      echo "Updating $routetable with IPv6 default route to $TARGETIGW."
      aws ec2 create-route --output json --region $region --route-table-id $routetable --gateway-id $TARGETIGW --destination-ipv6-cidr-block "::/0"
    done

    # The following updates all Security Groups in the VPC to allow IPv6 traffic outbound. This occurs on every Security Group, so it may not fit everyone's use case. 
    # Disable if you don't want some Security Groups to allow access to the Internet for IPv6 traffic. Generally we do, so it is enabled by default.
    for securitygroup in `aws ec2 describe-security-groups --output json --region $region | grep -A 3 "$vpcid" | grep -oh "\w*sg-\w*"`; do
      echo "Updating $securitygroup to allow IPv6 traffic. $(aws ec2 describe-security-groups --output json --region $region --group-id "$securitygroup" | grep GroupName)"
      aws ec2 authorize-security-group-ingress --output json --region $region --group-id $securitygroup --ip-permissions '[{"Ipv6Ranges":[{"CidrIpv6":"::/0"}], "IpProtocol":"-1"}]'
    done

    # Verify that the VPC got an IPv6 assignment.
    aws ec2 describe-vpcs --output json --region $region --vpc-id $vpcid | grep -A 8 "Ipv6CidrBlockAssociationSet"

    echo "Remember to allocate subnets for each VPC or you won't be using any of your assigned CIDR block."
    # aws ec2 associate-subnet-cidr-block --output json --region $region --subnet-id $TARGETSUB --ipv6-cidr-block <::/64>
    # aws ec2 modify-subnet-attribute --output json --region $region --subnet $TARGETSUB --assign-ipv6-address-on-creation
    # aws ec2 modify-subnet-attribute --output json --region $region --subnet $TARGETSUB --map-public-ip-on-launch

    echo ""
    echo "----"
    echo "$region: $vpcid is now enabled for IPv6!"
    echo "----"

  done

  echo "$region Completed."
  echo "===="
done
