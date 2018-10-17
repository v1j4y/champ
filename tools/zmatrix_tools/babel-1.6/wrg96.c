/* $Id: wrg96.c,v 1.1 1996/06/25 12:25:18 wscott Exp $
   contributed by Walter Scott (wscott@igc.phys.chem.ethz.ch)

   (Actually the routine was copied from write_xyz and and write_pdb and
   then modified...)

   This is a small routine to write a GROMOS96 formatted 
   "position coordinate block" (POSITION) or a
   "reduced position coordinate block" (POSITIONRED)
   The former has name information (atom and residue names) while
   the latter only has coordinates.
   This version does not support the writing of binary
   GROMOS files.

   NOTE 1: the actual formats used in writing out the coordinates
   do not matter, as GROMOS96 uses free formatted reads.
   Each line may not be longer than 80 characters.

   (Note, however, in the POSITION block, the first 24 (twenty four)
   character on each line are ignored when the line is read in by GROMOS)
   Comments lines, beginning with hash (#) may occur within a block and are
   used as delimiters for easier reading.

   NOTE 2: Many programs specify the units of the coordinates (e.g. Angstrom).
   GROMOS96 does NOT, as all physical constants, from K_B to EPS are 
   NOT hardwired into the code, but specified by the user.
   This allows some (mostly Americans) to use GROMOS96 in KCal and
   Angstrom and the rest of us to use kJoule and nm.
   It also makes it easy to use reduced units.

   We get around this by supplying a routine, wr_sco_gr96, which
   will scale the coordinates by a factor before writing.
   This routine is then called with the factor set to 1.0 in 
   write_gr96A, or to 0.1 in write_gr96N depending on the users choice.
   Thus, we always assume that we have read coordinates in Angstrom.
*/

#include "bbltyp.h"


int wr_sco_gr96(FILE *file1, ums_type *mol,double fac){ 
   int i;
   char type_name[5];
   char the_res[5];
   int res_num;
   int result;
/*begin*/
   /* first a little comment*/
   fprintf(file1,"#GENERATED BY BABEL %s\n",BABEL_VERSION);

   /* GROMOS wants a TITLE block, so let's write one*/
   fprintf(file1,"TITLE\n%s\nEND\n",Title);

   /*now the coordinates*/
   if (HasResidues) {
      /* write a POSITION block*/
      fprintf(file1,"POSITION\n");
      for(i = 1;i <= Atoms; i++){
	 strcpy(the_res,ResName(i));
	 strcpy(type_name,AtmId(i));
	 res_num = ResNum(i);

	 fprintf(file1,"%5d %5s %5s %6d %15.5f %15.5f %15.5f\n",
		 res_num,the_res,type_name,i,
		 X(i)*fac,Y(i)*fac,Z(i)*fac);

	 if (i % 10 ==0){
	    fprintf(file1,"# %d\n",i);
	 }
      }
   }else{
      /* write a POSITIONRED block*/
      fprintf(file1,"POSITIONRED\n");
      for(i = 1;i <= Atoms; i++){
	 result = get_output_type(i,"XYZ",Type(i),type_name,all_caps);
	 fprintf(file1,"%15.5f %15.5f %15.5f\n",
		 X(i)*fac,Y(i)*fac,Z(i)*fac);
	 if (i % 10 ==0){
	    fprintf(file1,"# %d\n",i);
	 }
      }
   }
   fprintf(file1,"END\n");
   return(TRUE);
}



/* these are the routines that babel calls */
int write_gr96A(FILE *file1, ums_type *mol){ 
   return wr_sco_gr96(file1,mol,1.0);
}


/* convert A -> nm */
int write_gr96N(FILE *file1, ums_type *mol){ 
   return wr_sco_gr96(file1,mol,0.1);
}
