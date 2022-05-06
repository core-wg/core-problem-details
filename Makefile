LIBDIR := lib
include $(LIBDIR)/main.mk

$(LIBDIR)/main.mk:
ifneq (,$(shell grep "path *= *$(LIBDIR)" .gitmodules 2>/dev/null))
	git submodule sync
	git submodule update $(CLONE_ARGS) --init
else
	git clone -q --depth 10 $(CLONE_ARGS) \
	    -b main https://github.com/martinthomson/i-d-template $(LIBDIR)
endif

all.cddl: draft-ietf-core-problem-details.xml
	xmlstarlet sel -T -t -v '//sourcecode[@type="cddl"]' ./draft-ietf-core-problem-details.xml 2>/dev/null > $@.new
	mv $@.new $@

gen-from-cddl: all.cddl
	cddl $^ gp 10

