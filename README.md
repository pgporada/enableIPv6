# enableIPv6Globally #

This is a shell script built to search the user's AWS account for VPCs in each region, and enable IPv6 capabilities on each. This tool goes as far as associating an Amazon-provided IPv6 CIDR block for each VPC found, updating all Route Tables in each VPC to include a default route for IPv6 traffic to the IGW, and update Security Groups to include rules to allow IPv6 traffic. The results (successes and failures alike) are saved in the resulting log file, stored in the same directory the script is launched from.

What this script does not do is add subnets with new IPv6 address space (you must do that on your own or modify the code to do so). It does not launch new resources, just modifies existing ones.

Ideally I'd have this script be written using the SDK for a more clean and expandable tool, but this is the current build and should work for most.

# How To Use It #

1. Configure the awscli on your workstation. Ensure you have a Bash shell available in /usr/bin/env. (You likely do.)
2. Modify the script such that the REGIONLIST array contains all the regions you want IPv6 to be used in. The full list is included - just uncomment the appropriate line to use it.
3. Run the src/enableIPv6Globally.sh script. 

# Known Issues #

As of today's launch, this script should only work in us-east-2 (Ohio), but should function when new regions are added.

# If You Run Into Trouble #

Open an Issue. I made this for my own needs and am offering it as a best-effort sharing of knowledge to the world, and will work on issues in the same best-effort approach.
