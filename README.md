# Monash Tessera Stack

## Install

```{bash}
<!-- for all servers -->
source install_1_apt_get
source install_2_hadoop

<!-- wait for all to finish -->

<!-- for all servers -->
source install_3_format

<!-- wait for all to finish -->

<!-- for all servers (restarts servers) -->
source install_4_format
```

Test example
```{bash}
SERVERS="monash tessera-wn1 tessera-wn2 tessera-wn3"

for SERVER in $SERVERS;
do
  echo "





  "
  echo "Installing Server: $SERVER

  "
  ssh $SERVER 'mkdir ~/z_install'
  scp ./monash_slaves $SERVER:z_install/monash_slaves
  scp ./install_0_setup $SERVER:z_install/install_0_setup
  scp ./install_1_apt_get $SERVER:z_install/install_1_apt_get
  scp ./install_2_hadoop $SERVER:z_install/install_2_hadoop
  scp ./install_3_format $SERVER:z_install/install_3_format
  scp ./install_4_hdfs $SERVER:z_install/install_4_hdfs

  ssh $SERVER 'cd z_install; source install_1_apt_get'
done



for SERVER in $SERVERS;
do
echo "Updating hadoop on Server: $SERVER

"  
  ssh $SERVER 'cd z_install; source install_2_hadoop'
done



for SERVER in $SERVERS;
do
echo "


"
echo "Updating format on Server: $SERVER

"  
  ssh $SERVER 'cd z_install; source install_3_format'
done


for SERVER in $SERVERS;
do
echo "Updating hdfs on Server: $SERVER

"  
  ssh $SERVER 'cd z_install; source install_4_hdfs'
done
```


## R

Run the commands in the R folder to see how a distributed calculations could be done.  

Make sure to port forward port 4000 to view the trelliscope server.
