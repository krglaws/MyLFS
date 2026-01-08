#Lz4 Phase 4
make BUILD_STATIC=no PREFIX=/usr
make -j1 check
make BUILD_STATIC=no PREFIX=/usr install
