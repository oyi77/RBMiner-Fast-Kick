#!/bin/bash
echo "Installing Everything to Be Gendeng Anyaran"
apt install pciutils
chmod +x *.sh
mv setup.json _setup.json.orig
cd ..
FILE=setup.json
if [ -f "$FILE" ]; then
    mv setup.json RBMiner-Fast-Kick/setup.json
else 
    mv RBMiner-Fast-Kick/_setup.json.orig RBMiner-Fast-Kick/setup.json 
fi
cd RBMiner-Fast-Kick
./install.sh
./start-screen.sh