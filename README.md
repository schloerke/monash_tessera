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
  echo "Copying files to Server: $SERVER

  "
  ssh $SERVER 'mkdir ~/z_install'
  scp ./monash_slaves $SERVER:z_install/monash_slaves
  scp ./install_* $SERVER:z_install/

  ssh $SERVER 'cd z_install; source install_1_apt_get'
done


for SERVER in $SERVERS;
do
  echo "





  "
  echo "Installing Server: $SERVER

  "
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

Make sure to port forward port 4000 to view the trelliscope server.  I'd recommend performing one line at a time and exploring each data object along the way.

```
ssh tessera
R
```
```{r}
# load housing data and work with datadr
source("R/monash_test_rhipe_datadr.R")


# load housing data and produce a trelliscope view
source("R/monash_test_trelliscope.R")
```
