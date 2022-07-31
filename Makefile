.SILENT:
PACKAGE_NAME := evon-hub
EC2_HOST := ec2-user@ec2-13-236-148-138.ap-southeast-2.compute.amazonaws.com
ENV := dev


help: # Show this help
	@echo Make targets:
	@egrep -h ":\s+# " $(MAKEFILE_LIST) | \
	  sed -e 's/# //; s/^/    /' | \
	  column -s: -t

test: # Run unit tests
	pytest evon/
	flake8 --ignore=E501 evon/

package: # produce package artefact ready for publishing
	# create archive
	rm -f /tmp/evon_hub.tar.gz || :
	tar -zcf /tmp/evon_hub.tar.gz --exclude '*.log' --exclude '*.swp' --exclude .gitignore --exclude .git --exclude .env ansible evon bootstrap requirements.txt version.txt setup.py
	# Generate output package filename
	$(eval NAME=$(PACKAGE_NAME)-$(BRANCH))
	$(eval GITCOUNT=$(shell git rev-list HEAD --count))
	$(eval VER=$(shell cat version.txt).$(GITCOUNT))
	$(eval OUTFILE=$(PACKAGE_NAME)_$(VER).sh)
	# write final package
	cp package_template.sh $(OUTFILE)
	cat /tmp/evon_hub.tar.gz | base64 >> $(OUTFILE)
	# cleanup
	rm -f /tmp/evon_hub.tar.gz
	sed -i 's/__VERSION__/$(VER)/g' $(OUTFILE)
	echo Wrote package file: $(OUTFILE)

publish: # publish package
	scp evon-hub_*.sh  $(EC2_HOST):evon-hub_latest.sh
	rm -f evon-hub_*.sh
	# TODO publish to S3, create API endpoint to pull latest, make script to pull/update/manage versions.

deploy: # make package, publish and run installer on remote host
	#make test #TODO uncomment
	make package
	make publish
	echo "Deploying to host: $(EC2_HOST)"
	ssh $(EC2_HOST) "chmod +x evon-hub_latest.sh; bash --login -c 'sudo ./evon-hub_latest.sh'; rm -f evon-hub_latest.sh"
