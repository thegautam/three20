set -e

dest=../../Build/Products/three20

cp ../../src/Three20/Headers/Three20.h $dest/Three20
cp ../../src/Three20/Headers/Three20+Additions.h $dest/Three20

mkdir -p $dest/Three20Core/private
cp -R ../../src/Three20Core/Headers/ $dest/Three20Core/
cp -R ../../src/Three20Core/Headers/ $dest/Three20Core/private/

mkdir -p $dest/Three20Network/private
cp -R ../../src/Three20Network/Headers/ $dest/Three20Network/
cp -R ../../src/Three20Network/Headers/ $dest/Three20Network/private/

mkdir -p $dest/Three20Style/private
cp -R ../../src/Three20Style/Headers/ $dest/Three20Style/
cp -R ../../src/Three20Style/Headers/ $dest/Three20Style/private/

mkdir -p $dest/Three20UICommon/private
cp -R ../../src/Three20UICommon/Headers/ $dest/Three20UICommon/
cp -R ../../src/Three20UICommon/Headers/ $dest/Three20UICommon/private/

mkdir -p $dest/Three20UINavigator/private
cp -R ../../src/Three20UINavigator/Headers/ $dest/Three20UINavigator/
cp -R ../../src/Three20UINavigator/Headers/ $dest/Three20UINavigator/private/

mkdir -p $dest/Three20UI/private
cp -R ../../src/Three20UI/Headers/ $dest/Three20UI/
cp -R ../../src/Three20UI/Headers/ $dest/Three20UI/private/



