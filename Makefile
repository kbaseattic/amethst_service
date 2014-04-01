DEPLOY_RUNTIME ?= /kb/runtime
TARGET ?= /kb/deployment

TOP_DIR = ../..
include $(TOP_DIR)/tools/Makefile.common


SERVICE_SPEC = amethst.spec      
SERVICE_NAME = AmethstService
SERVICE_PORT = 7109
SERVICE_DIR  = amethst_service

ifeq ($(SELF_URL),)
	SELF_URL = http://localhost:$(SERVICE_PORT)
endif

SERVICE_PSGI = $(SERVICE_NAME).psgi

TPAGE_ARGS = --define kb_runas_user=$(SERVICE_USER) --define kb_top=$(TARGET) --define kb_runtime=$(DEPLOY_RUNTIME) --define kb_service_name=$(SERVICE_NAME) --define kb_service_dir=$(SERVICE_DIR) --define kb_service_port=$(SERVICE_PORT) --define kb_psgi=$(SERVICE_PSGI)

TOOLS_DIR = $(TOP_DIR)/tools
WRAP_PERL_TOOL = wrap_perl
WRAP_PERL_SCRIPT = bash $(TOOLS_DIR)/$(WRAP_PERL_TOOL).sh
SRC_PERL = $(wildcard plbin/*.pl)


deploy: deploy-all


deploy-all: initialize deploy-client deploy-service


deploy-client: deploy-libs deploy-scripts

deploy-libs: build-libs
	rsync --exclude '*.bak*' -arv MG-RAST-Tools/tools/lib/. $(TARGET)/lib/.


DEPRECATEDdeploy-scripts: initialize
	export KB_TOP=$(TARGET); \
	export KB_RUNTIME=$(DEPLOY_RUNTIME); \
	export KB_PERL_PATH=$(TARGET)/lib bash ; \
	for src in $(SRC_PERL) ; do \
		basefile=`basename $$src`; \
		base=`basename $$src .pl`; \
		echo install $$src $$base ; \
		mkdir -p $(TARGET)/plbin/ ; \
		cp $$src $(TARGET)/plbin/ ; \
		$(WRAP_PERL_SCRIPT) "$(TARGET)/plbin/$$basefile" $(TARGET)/bin/$$base ; \
	done
	cp -r AMETHST $(TARGET)/services/$(SERVICE_DIR)/



deploy-service: deploy-cfg
	mkdir -p $(TARGET)/services/$(SERVICE_DIR)
	$(TPAGE) $(TPAGE_ARGS) service/start_service.tt > $(TARGET)/services/$(SERVICE_DIR)/start_service
	chmod +x $(TARGET)/services/$(SERVICE_DIR)/start_service
	$(TPAGE) $(TPAGE_ARGS) service/stop_service.tt > $(TARGET)/services/$(SERVICE_DIR)/stop_service
	chmod +x $(TARGET)/services/$(SERVICE_DIR)/stop_service
	$(TPAGE) $(TPAGE_ARGS) service/upstart.tt > service/$(SERVICE_NAME).conf
	chmod +x service/$(SERVICE_NAME).conf
	rm -rf $(TARGET)/services/$(SERVICE_DIR)/AMETHST/
	cp -r AMETHST $(TARGET)/services/$(SERVICE_DIR)/
	echo "done executing deploy-service target"

.PHONY : initialize
initialize:
	git submodule init
	git submodule update
	git submodule foreach git pull origin master

deploy-upstart: deploy-service
	-cp service/$(SERVICE_NAME).conf /etc/init/
	echo "done executing deploy-upstart target"

build-libs:
	mkdir -p lib/Bio/KBase/AmethstService/
	cp impl_code.txt lib/Bio/KBase/AmethstService/AmethstServiceImpl.pm
	compile_typespec \
		--psgi $(SERVICE_PSGI)  \
		--impl Bio::KBase::$(SERVICE_NAME)::$(SERVICE_NAME)Impl \
		--service Bio::KBase::$(SERVICE_NAME)::Service \
		--client Bio::KBase::$(SERVICE_NAME)::Client \
		--py biokbase/$(SERVICE_NAME)/Client \
		--js javascript/$(SERVICE_NAME)/Client \
		--url $(SELF_URL) \
		$(SERVICE_SPEC) lib


include $(TOP_DIR)/tools/Makefile.common.rules

