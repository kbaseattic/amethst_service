amethst service
===============

AMETHST, or Analysis METHod Selection Tool, is an automated pipeline that makes it possible to objectively assess the relative performance of multiple analysis methods applied to annotation abundance data. Utilizing objective, permutation-based statistics, it can determine the best performing analysis from any arbitrary collection of analyses, and can also determine the degree to which each analysis step (e.g. normalization and reprocessing of the data, selection of distance/dissimilarity metric) affects the results produced by each analysis method.




Deployment in KBase
===================

configure deploy.cfg



> make<br>

one of:
> make deploy-client<br>
> make deploy-service<br>
> make deploy-backend<br>
> make deploy-all<br>

then
> source /kb/deployment/user-env.sh<br>

one of
> make test-client<br>
> make test-service<br>
> make test-backend<br>
> make test<br>


Creating a backend compute VM
=============================
Script location (the script is located in the AMETHST repository linked to this amethst_service repository):
\AMETHST\installation\Install_AMETHST_compute_node.havannah.sh

Script should be executed with envrionment variables that include KB_AUTH_TOKEN and AWE_CLIENT_GROUP_TOKEN:
> sudo -E Install_AMETHST_compute_node.havannah.sh



Instructions to install amethst client script independently
===========================================================

USAGEPOD
--------
> wget https://raw.githubusercontent.com/wgerlach/USAGEPOD/master/lib/USAGEPOD.pm

SHOCK
-----
> mkdir SHOCK
> cd SHOCK
> wget https://raw.githubusercontent.com/MG-RAST/Shock/master/libs/SHOCK/Client.pm
> cd ..

amethst client script
---------------------
> wget https://raw.githubusercontent.com/kbase/amethst_service/master/plbin/mg-amethst.pl
> chmod +x mg-amethst.pl

