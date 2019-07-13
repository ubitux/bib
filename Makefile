OPENSCAD_EXTRA_SETTINGS = --camera=500,0,500,70,0,325,3600
OPENSCAD ?= openscad --colorscheme="Tomorrow Night" --imgsize=3840,2160 $(OPENSCAD_EXTRA_SETTINGS)
DSCALE   ?= scale=iw/2:ih/2:flags=lanczos
FFMPEG ?= ffmpeg

NAME = bib
IFILE = $(NAME).scad

PIECES = h_plank_mid       \
         h_plank_tb        \
         v_plank_lr        \
         v_plank_mid_back  \
         v_plank_mid_front \
         back_holder       \

DXF_PREFIX = piece-
DXF_SUFFIX = .dxf
DXFS = $(addprefix $(DXF_PREFIX),$(addsuffix $(DXF_SUFFIX),$(PIECES)))

dxf: $(DXFS)

STEPS ?= 600
FPS   ?= 60

# broken (rebuild everytime)
$(DXF_PREFIX)%$(DXF_SUFFIX): %
	@

$(PIECES): $(IFILE)
	$(OPENSCAD) $(IFILE) -D show_parts=true -D project_2d=true -D 'piece="$@"' -o $(DXF_PREFIX)$@$(DXF_SUFFIX)

$(NAME).svg: $(IFILE)
	$(OPENSCAD) $(IFILE) -D show_parts=true -D project_2d=true -o $@

$(NAME).png: $(NAME).svg
	convert $< $@

define anim_pattern
%$(shell printf $(1) | wc -c)d
endef

define anim_pictures
$(addsuffix .png,$(addprefix anim-,$(shell seq -w $(1))))
endef

define dashsplit
$(word $(1),$(subst -, ,$(2)))
endef

ANIM_PATTERN := $(call anim_pattern,$(STEPS))

anim-%.png: NUM = $(shell echo $(call dashsplit,1,$*) | sed 's/^0*//')
anim-%.png: $(NAME).scad
	$(OPENSCAD) $< -D'$$t=$(NUM)/$(STEPS)' -Danimated=true -o $@

.SECONDEXPANSION: # XXX: wtf make...
$(NAME).mp4: $$(call anim_pictures,$(STEPS))
	$(FFMPEG) -framerate $(FPS) -i anim-$(ANIM_PATTERN).png -vf $(DSCALE) -pix_fmt yuv420p -movflags +faststart -y $@

clean:
	$(RM) $(DXFS)
	$(RM) anim-*.png

.PHONY: all clean
