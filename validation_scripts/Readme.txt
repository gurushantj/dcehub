#Make sure you have goss installed where you want to run the script if not you can install it using below two commands:

# Install latest version to /usr/local/bin
curl -fsSL https://goss.rocks/install | sh

# Install v0.3.6 version to ~/bin
curl -fsSL https://goss.rocks/install | GOSS_VER=v0.3.6 GOSS_DST=~/bin sh


# Install jq package on vm where we are running goss scripts
apt-get install -y jq


#Command to run goss validation script on compute baremetal.Similarly we can validate ppvm and orch by going into their respective folders.
cd dcehub/validation_scripts/compute_baremetal
goss validate

#In case if you want detailed output then use following command
goss validate -f json | python -m json.tool > out.json
vim out.json
