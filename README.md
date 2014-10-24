amethst service
===============

AMETHST, or Analysis METHod Selection Tool, is an automated pipeline that makes it possible to objectively assess the relative performance of multiple analysis methods applied to annotation abundance data. Utilizing objective, permutation-based statistics, it can determine the best performing analysis from any arbitrary collection of analyses, and can also determine the degree to which each analysis step (e.g. normalization and reprocessing of the data, selection of distance/dissimilarity metric) affects the results produced by each analysis method.




Deployment in KBase
-------------------

configure deploy.cfg


```bash
make
```

one of:
```bash
make deploy-client
make deploy-service
make deploy-backend
make deploy-all
```

then
```bash
source /kb/deployment/user-env.sh
```

one of
```shell
make test-client
make test-service
make test-backend
make test
```

Creating a backend compute VM
-----------------------------
Script location (the script is located in the AMETHST repository linked to this amethst_service repository):
```bash
AMETHST/installation/Install_AMETHST_compute_node.havannah.sh
```

Script should be executed with envrionment variables that include KB_AUTH_TOKEN and AWE_CLIENT_GROUP_TOKEN:
```bash
sudo -E Install_AMETHST_compute_node.havannah.sh
```


Instructions to install amethst client script independently
-----------------------------------------------------------

USAGEPOD library

```bash
wget https://raw.githubusercontent.com/wgerlach/USAGEPOD/master/lib/USAGEPOD.pm
```

SHOCK client library

```bash
mkdir SHOCK
cd SHOCK
wget https://raw.githubusercontent.com/MG-RAST/Shock/master/libs/SHOCK/Client.pm
cd ..
```

amethst client script

```bash
wget https://raw.githubusercontent.com/kbase/amethst_service/master/plbin/mg-amethst.pl
chmod +x mg-amethst.pl
```

configuration to use KBase amethst service

```bash
export SHOCK_SERVER_URL=
export KB_AUTH_TOKEN=<your kbase token>
```

The token can also be passed with --token=<token> to mg-amethst.pl
