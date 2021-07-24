echo "Installing Everything to Be Gendeng Anyaran"
move setup.json _setup.json.orig
cd ..
IF EXIST "setup.json" (
  move setup.json RBMiner-Fast-Kick/setup.json
) ELSE (
  move RBMiner-Fast-Kick/_setup.json.orig RBMiner-Fast-Kick/setup.json 
)

cd RBMiner-Fast-Kick
call Install.bat
call StartHidden.bat