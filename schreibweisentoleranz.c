/*
 * schreibweisentoleranz.c -- 
 *
 * Copyright (c) 2005 Directmedia GmbH
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 2 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program; if not, write to the Free Software
 *   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

#include <stdlib.h>
#include <string.h>


char *phoneticAtom(const char *s1,int inSet)
{
int q;
char n,n1;
char *Result;

Result = calloc(4096,1);
	
	if (inSet)  {
		strcat(Result,s1);
		return Result;  
	} else {
		q = 0;
		while (q<strlen(s1))  {
			if (q+1<strlen(s1))  {
				n = s1[q+1];
				if (q+2<strlen(s1))  {
					n1 = s1[q+2];
				} else {
					n1 = 0;
				}
			} else {
				n = 0; n1 = 0;
			}
			
			// {a}
			if (s1[q]=='a')  {
				if ((n=='y') || (n=='i'))  {
					strcat(Result,"[ae][yi]"); q++;
				} else if (n=='e')  {
					strcat(Result,"ae?"); q++;
				} else if (n=='a')  {
					strcat(Result,"a[ah]?"); q++;
				} else {
					strcat(Result,"ah?");
				}
				
			} 
/*
 // {}
				else if (s1[q]=="")  {
				if n in ['e', 'E', #200..#203, #232..#235]  {
					strcat(Result,"[ae][eh][ae]?"); q++;
				} else if n==""  {
					strcat(Result,"[ae][eh]?"); q++;
				} else {
					strcat(Result,"[ae][eh]?");
				}
				
				// {c}
			}
*/
				else if (s1[q]=='c')  {
				if ((n=='i') || (n=='e') || (n=='y'))  {
					strcat(Result,"[czk]?")+n; q++;
				} else if ((n=='k') || (n=='c'))  {
					if (n1=='l')  {
						strcat(Result,"[ck]{1,2}e?l"); q+=2;
					} else {
						strcat(Result,"[ck]{1,2}"); q++;
					}
				} else if (n=='h')  {
					strcat(Result,"[ck]{1,2}h?"); q++;
				} else {
					strcat(Result,"[ck]{1,2}");
				}
				
				// {Á}
			} 
/*			else if (s1[q]=='Á')  {
				strcat(Result,"s");

				
				// {e}
			} */
			else if (s1[q]=='e')  {
				if ((n=='i') || (n=='y'))  {
					strcat(Result,"[ae][yiu]h?"); q++;
				} else if ((n=='l') && (n1=='f'))  {
					strcat(Result,"ei?lf"); q+=2;
				} else if (n=='e')  {
					strcat(Result,"[e]{1,2}h?"); q++;
				} else {
					strcat(Result,"[e]h?");
				}
				
				// {f}
			} else if (s1[q]=='f')  {
				if  (n=='a' || n=='e' || n=='i' || n=='o' || n=='u' || n=='l' || n=='y') {
					strcat(Result,"[fp]f?h?");
				} else if (n=='f')  {
					strcat(Result,"f{1,2}"); q++;
				} else {
					strcat(Result,"f{1,2}");
				}
				
				// {h}
			} else if (s1[q]=='h')  {
				if (n=='n')  {
					strcat(Result,"h?e?n"); q++;
				} else if ((n=='e') && (n1=='n'))  {
					strcat(Result,"h?e?n"); q++; q++;
				} else {
					strcat(Result,"h?");
				}
				
				// {i}
			} else if (s1[q]=='i')  {
				if (n=='e')  {
					strcat(Result,"[i¸y][eh]?"); q++;
				} else if (n=='g')  {
					strcat(Result,"[i¸y][cgeh]?"); q++;
				} else {
					strcat(Result,"[i¸y][eh]?");
				}
				
				// {j}
			} else if (s1[q]=='j')  {
				strcat(Result,"[ij]");
				
				// {k}
			} else if (s1[q]=='k')  {
				if (n=='k')  {
					strcat(Result,"[ck]{1,2}"); q++;
				} else if (n=='c')  {
					strcat(Result,"k[ck]{1,2}"); q++;
				} else {
					strcat(Result,"[ck]{1,2}h?");
				}
				
				// {l}
			} else if (s1[q]=='l')  {
				if (n=='l')  {
					strcat(Result,"l{1,2}"); q++;
				} else {
					strcat(Result,"l{1,2}");
				}
				
				// {m}
			} else if (s1[q]=='m')  {
				if (n=='m')  {
					strcat(Result,"m{1,2}"); q++;
				} else {
					strcat(Result,"m{1,2}");
				}
				
				// {n}
			} else if (s1[q]=='n')  {
				if (n=='n')  {
					strcat(Result,"n{1,2}"); q++;
				} else {
					strcat(Result,"n{1,2}");
				}
				
				// {o}
			} else if (s1[q]=='o')  {
				if (n=='e')  {
					strcat(Result,"oe?h?"); q++;
				} else if (n=='o')  {
					strcat(Result,"o{1,2}h?");  q++;
				} else if (n=='u')  {
					strcat(Result,"o?uh?");  q++;
				} else {
					strcat(Result,"oh?");
				}
				
				// {ˆ}
			} 
			/*
			else if (s1[q]=="ˆ")  {
				if (n=='e')  {
					strcat(Result,"[oe][ˆeh]?"); q++;
				} else if (n=="ˆ")  {
					strcat(Result,"[oe][ˆeh]?"); q++;
				} else {
					strcat(Result,"[oe][ˆeh]?");
				}
				
				// {p}
			}
			 */
			 else if (s1[q]=='p')  {
				if (n=='h')  {
					strcat(Result,"[pf]h?"); q++;
				} else if (n=='p')  {
					strcat(Result,"p{1,2}"); q++;
				} else {
					strcat(Result,"p");
				}
				
				// {s}
			} else if (s1[q]=='s')  {
				if (n=='s')  {
					strcat(Result,"s{1,2}"); q++;
				} else if (n=='c')  {
					strcat(Result,"s[ck]?"); q++;
				} else if (n=='z')  {
					strcat(Result,"s[zc]h?"); q++;
				} /* else if (n =='ﬂ' || n=='Á')  {
					strcat(Result,"s{1,2}"); q++;
				} */ 
				else {
					strcat(Result,"s{1,2}");
				}
				
				// {ﬂ}
			}
			/* else if (s1[q]=="ﬂ")  {
				if ( n=='s' || n=='ﬂ' || n=='Á'  )  {
					strcat(Result,"s{1,3}"); q++;
				} else {
					strcat(Result,"s{1,2}");
				}
				
				// {u}
			} */
			else if (s1[q]=='u')  {
				if (n=='e')  {
					strcat(Result,"ue?h?"); q++;
				} else {
					strcat(Result,"[uv]h?");
				}
				
				// {¸}
			} 
		/*else if (s1[q]=="¸")  {
				if (n=='e')  {
					strcat(Result,"[uiy]e?h?"); q++;
				} else {
					strcat(Result,"[uiy]e?h?");
				}
				
				
			} */
		// {t}
		else if (s1[q]=='t')  {
				if (n=='h')  {
					strcat(Result,"th?"); q++;
				} else if (n=='i')  {
					if (n1=='e')  {
						strcat(Result,"[tz]i[eh]?"); q+=2;
					} else {
						strcat(Result,"[tz]i"); q++;
					}
				} else if (n=='t')  {
					strcat(Result,"t{1,2}h?"); q++;
				} else if (n=='z')  {
					strcat(Result,"t?z"); q++;
				} else {
					strcat(Result,"th?");
				}
				
				// {y}
			} else if (s1[q]=='y')  {
				strcat(Result,"[iy¸]");
				
				// {z}
			} else if (s1[q]=='z')  {
				strcat(Result,"t?[zc]");
				
			} else {
				strncat(Result,&s1[q],1);
			}
			q++;
		}
	}
return Result;
}
