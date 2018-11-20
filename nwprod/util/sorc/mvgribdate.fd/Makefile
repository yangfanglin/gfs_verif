################################################################################
SHELL=	/bin/sh
CMD=	../../exec/mvgribdate
FOPTS=	$(FFLAGS)
LOPTS=	$(LFLAGS)
INCS=	
OBJS=	mvgribdate.o
LIBS= -L$(LIBDIR) -lbacio_4 -l$(W3LIB)	
################################################################################
$(CMD):	$(OBJS)
	$(FCMP) $(LOPTS) $(OBJS) $(LIBS) -o $(CMD)
$(OBJS):	$(INCS)
mvgribdate.o:	mvgribdate.f
	$(FCMP) -c $(FOPTS) $*.f
clean:	
	-rm -f $(OBJS)
