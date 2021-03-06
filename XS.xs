/*
 * $Id: XS.xs,v 0.9 2015/06/27 00:28:39 dankogai Exp dankogai $
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* #include "ppport.h" */
/* #include <URI::Escape::XS> */

# include <stdio.h>
# include <stdlib.h>
# include <string.h>
# include <ctype.h>

/*
 * Table has a 0 if that character doesn't need to be encoded;
 * otherwise it has a string with the character encoded in hex digits.
 */
static char* uri_encode_tbl[256] =
/*    0     1     2     3     4     5     6     7     8     9     a     b     c     d     e     f */
{
    "00", "01", "02", "03", "04", "05", "06", "07", "08", "09", "0A", "0B", "0C", "0D", "0E", "0F",  /* 0:   0 ~  15 */
    "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "1A", "1B", "1C", "1D", "1E", "1F",  /* 1:  16 ~  31 */
    "20",   0 , "22", "23", "24", "25", "26",   0 ,   0 ,   0 ,   0 , "2B", "2C",   0 ,   0 , "2F",  /* 2:  32 ~  47 */
      0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 , "3A", "3B", "3C", "3D", "3E", "3F",  /* 3:  48 ~  63 */
    "40",   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,  /* 4:  64 ~  79 */
      0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 , "5B", "5C", "5D", "5E",   0 ,  /* 5:  80 ~  95 */
    "60",   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,  /* 6:  96 ~ 111 */
      0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 ,   0 , "7B", "7C", "7D",   0 , "7F",  /* 7: 112 ~ 127 */
    "80", "81", "82", "83", "84", "85", "86", "87", "88", "89", "8A", "8B", "8C", "8D", "8E", "8F",  /* 8: 128 ~ 143 */
    "90", "91", "92", "93", "94", "95", "96", "97", "98", "99", "9A", "9B", "9C", "9D", "9E", "9F",  /* 9: 144 ~ 159 */
    "A0", "A1", "A2", "A3", "A4", "A5", "A6", "A7", "A8", "A9", "AA", "AB", "AC", "AD", "AE", "AF",  /* A: 160 ~ 175 */
    "B0", "B1", "B2", "B3", "B4", "B5", "B6", "B7", "B8", "B9", "BA", "BB", "BC", "BD", "BE", "BF",  /* B: 176 ~ 191 */
    "C0", "C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C9", "CA", "CB", "CC", "CD", "CE", "CF",  /* C: 192 ~ 207 */
    "D0", "D1", "D2", "D3", "D4", "D5", "D6", "D7", "D8", "D9", "DA", "DB", "DC", "DD", "DE", "DF",  /* D: 208 ~ 223 */
    "E0", "E1", "E2", "E3", "E4", "E5", "E6", "E7", "E8", "E9", "EA", "EB", "EC", "ED", "EE", "EF",  /* E: 224 ~ 239 */
    "F0", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "FA", "FB", "FC", "FD", "FE", "FF",  /* F: 240 ~ 255 */
};

/*
 * Table has a 0 if that character cannot be a hex digit;
 * otherwise it has the decimal value for that hex digit.
 */
static char uri_decode_tbl[256] =
/*    0    1    2    3    4    5    6    7    8    9    a    b    c    d    e    f */
{
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  /* 0:   0 ~  15 */
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  /* 1:  16 ~  31 */
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  /* 2:  32 ~  47 */
      0,   1,   2,   3,   4,   5,   6,   7,   8,   9,   0,   0,   0,   0,   0,   0,  /* 3:  48 ~  63 */
      0,  10,  11,  12,  13,  14,  15,   0,   0,   0,   0,   0,   0,   0,   0,   0,  /* 4:  64 ~  79 */
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  /* 5:  80 ~  95 */
      0,  10,  11,  12,  13,  14,  15,   0,   0,   0,   0,   0,   0,   0,   0,   0,  /* 6:  96 ~ 111 */
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  /* 7: 112 ~ 127 */
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  /* 8: 128 ~ 143 */
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  /* 9: 144 ~ 159 */
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  /* a: 160 ~ 175 */
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  /* b: 176 ~ 191 */
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  /* c: 192 ~ 207 */
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  /* d: 208 ~ 223 */
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  /* e: 224 ~ 239 */
      0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  /* f: 240 ~ 255 */
};

SV *encode_uri_component(SV *sstr){
    SV *str, *result;
    int slen, dlen;
    U8 *src, *dst;
    int i;
    if (sstr == &PL_sv_undef) return newSV(0);
    str    = sv_2mortal(newSVsv(sstr)); /* make a copy to make func($1) work */
    if (!SvPOK(str)) sv_catpv(str, "");
    slen   = SvCUR(str);
    dlen   = 0;
    result = newSV(slen * 3 + 1); /* at most 3 times */

    SvPOK_on(result);
    src   = (U8 *)SvPV_nolen(str);
    dst   = (U8 *)SvPV_nolen(result);

    for (i = 0; i < slen; i++) {
        char* v = uri_encode_tbl[(int)src[i]];

        /* if current source character doesn't need to be encoded,
           just copy it to target*/
        if (!v) {
            dst[dlen++] = src[i];
            continue;
        }

        /* copy encoded character from our table */
        dst[dlen++] = '%';
        dst[dlen++] = v[0];
        dst[dlen++] = v[1];
    }
    dst[dlen] = '\0'; /*  for sure; */
    SvCUR_set(result, dlen);
    return result;
}

SV *decode_uri_component(SV *suri){
    SV *uri, *result;
    int slen, dlen;
    U8 buf[8], *dst, *src, *bp;
    int i;
    if (suri == &PL_sv_undef) return newSV(0);
    /* if (!SvPOK(suri)) return newSV(0); */
    uri  = sv_2mortal(newSVsv(suri)); /* make a copy to make func($1) work */
    if (!SvPOK(uri)) sv_catpv(uri, "");
    slen = SvCUR(uri);
    dlen = 0;
    result = newSV(slen + 1);

    SvPOK_on(result);
    dst  = (U8 *)SvPV_nolen(result);
    src  = (U8 *)SvPV_nolen(uri);

    for (i = 0; i < slen; i++){
    	if (src[i] != '%') {
            dst[dlen++] = src[i];
            continue;
        }

	    if (isxdigit(src[i+1]) &&
            isxdigit(src[i+2])) {
            dst[dlen++] = ((uri_decode_tbl[(int)src[i+1]] << 4) |
                           (uri_decode_tbl[(int)src[i+2]]     ));
    		i += 2;
            continue;
	    }

	    if (src[i+1] == 'u' &&
		    isxdigit(src[i+2]) &&
            isxdigit(src[i+3]) &&
		    isxdigit(src[i+4]) &&
            isxdigit(src[i+5])) {
            unsigned int hi = ((uri_decode_tbl[(int)src[i+2]] << 12) |
                               (uri_decode_tbl[(int)src[i+3]] <<  8) |
                               (uri_decode_tbl[(int)src[i+4]] <<  4) |
                               (uri_decode_tbl[(int)src[i+5]]      ));
            memcpy(buf, src + i + 2, 4);
            buf[4] = '\0'; /* RT#39135 */
            i += 5;
    		if (hi < 0xD800  || 0xDFFF < hi){
    		    bp = uvchr_to_utf8((U8 *)buf, (UV)hi);
    		    memcpy(dst + dlen, buf, bp - buf);
    		    dlen += bp - buf;
    		} else {
    		    if (0xDC00 <= hi){ /* invalid */
        			warn("U+%04X is an invalid surrogate hi\n", hi);
    		    } else {
        			i++;
        			if (src[i] == '%' &&
                        src[i+1] == 'u' &&
        			    isxdigit(src[i+2]) &&
                        isxdigit(src[i+3]) &&
        			    isxdigit(src[i+4]) &&
                        isxdigit(src[i+5])) {
                        unsigned int lo = ((uri_decode_tbl[(int)src[i+2]] << 12) |
                                           (uri_decode_tbl[(int)src[i+3]] <<  8) |
                                           (uri_decode_tbl[(int)src[i+4]] <<  4) |
                                           (uri_decode_tbl[(int)src[i+5]]      ));
                        memcpy(buf, src + i + 2, 4);
                        buf[4] = '\0'; /* RT#39135 */
                        fprintf(stderr, "src [%*.*s], buf [%*.*s], lo [%X]\n",
                                6, 6, src + i, 4, 4, buf, lo);
                        i += 5;
        			    if (lo < 0xDC00 || 0xDFFF < lo){
            				warn("U+%04X is an invalid lo surrogate", lo);
        			    } else {
            				lo += 0x10000 + (hi - 0xD800) * 0x400 -  0xDC00;
            				bp = uvchr_to_utf8((U8 *)buf, (UV)lo);
            				memcpy(dst + dlen, buf, bp - buf);
            				dlen += bp - buf;
        			    }
        			} else {
        			    warn("lo surrogate is missing for U+%04X", hi);
        			}
    		    }
    		}
            continue;
	    }
        /* default case */
        dst[dlen++] = '%';
    }

    dst[dlen] = '\0'; /*  for sure; */
    SvCUR_set(result, dlen);
    return result;
}

SV *
decode_uri_component_fast(SV *suri)
{
    char a, b;
    SV *result;
    char *src, *dst;
    U8 buf[8], *bp;
    STRLEN len, cur;

    if (suri == &PL_sv_undef) return &PL_sv_no;

    cur = SvCUR(suri);
    src = SvPV(suri, len);

    result = newSV(len);
    dst    = SvPVX(result);
    SvPOK_on(result);

    while (*src) {
        if (src[0] == '%' &&
            isxdigit(src[1]) &&
            isxdigit(src[2]))
        {
            *dst++ = ((uri_decode_tbl[(int)src[1]] << 4) |
                      (uri_decode_tbl[(int)src[2]]     ));
            src += 3;
            cur -= 2;
        }
        else if (src[0] == '%' &&
                 src[1] == 'u' &&
                 isxdigit(src[2]) &&
                 isxdigit(src[3]) &&
                 isxdigit(src[4]) &&
                 isxdigit(src[5]))
        {
            unsigned int hi = ((uri_decode_tbl[(int)src[2]] << 12) |
                               (uri_decode_tbl[(int)src[3]] <<  8) |
                               (uri_decode_tbl[(int)src[4]] <<  4) |
                               (uri_decode_tbl[(int)src[5]]      ));
            memcpy(buf, src + 2, 4);
            buf[4] = '\0'; /* RT#39135 */
            src += 5;
            if (hi < 0xD800  || 0xDFFF < hi) {
                bp = uvchr_to_utf8((U8 *)buf, (UV)hi);
                memcpy(dst, buf, bp - buf);
                dst += bp - buf;
                cur -= 5 - (bp - buf);
            }
            else if (0xDC00 <= hi){ /* invalid */
                warn("U+%04X is an invalid surrogate hi\n", hi);
            }
            else {
                src++; /* hmm */
                if (src[0] == '%' &&
                    src[1] == 'u' &&
                    isxdigit(src[2]) &&
                    isxdigit(src[3]) &&
                    isxdigit(src[4]) &&
                    isxdigit(src[5]))
                {
                    unsigned int lo = ((uri_decode_tbl[(int)src[2]] << 12) |
                                       (uri_decode_tbl[(int)src[3]] <<  8) |
                                       (uri_decode_tbl[(int)src[4]] <<  4) |
                                       (uri_decode_tbl[(int)src[5]]      ));
                    memcpy(buf, src + 2, 4);
                    buf[4] = '\0';
                    src += 5;
                    if (lo < 0xDC00 || 0xDFFF < lo){
                        warn("U+%04X is an invalid lo surrogate", lo);
                    }
                    else {
                        lo += 0x10000
                              + (hi - 0xD800) * 0x400 -  0xDC00;
                        bp  = uvchr_to_utf8((U8 *)buf, (UV)lo);
                        memcpy(dst, buf, bp - buf);
                        dst += bp - buf;
                        cur -= 12 - (bp - buf);
                    }
                }
                else {
                    warn("lo surrogate is missing for U+%04X", hi);
                }
            }
        }
        else if (src[0] == '+') {
            *dst++ = ' ';
            src++;
        }
        else {
            *dst++ = *src++;
        }
    }
    *dst++ = '\0';

    SvCUR_set(result, cur);
    return result;
}

static OP *
S_pp_decode_uri_fast(pTHX)
{
    dSP;
    SV *src = POPs;
    PUTBACK;

    SV *ret = decode_uri_component_fast(src);
    sv_dump(ret);
    SPAGAIN;
    XPUSHs(ret);
    PUTBACK;

    return NORMAL;
}

static OP *
S_ck_decode_uri_fast(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)
{
    CV *cv = (CV*)ckobj;
    OP *pushop, *firstargop, *cvop, *lastargop, *argop, *newop;
    int arity;

    entersubop = ck_entersub_args_proto(entersubop, namegv, (SV*)cv);
    pushop = cUNOPx(entersubop)->op_first;
    if ( ! pushop->op_sibling )
        pushop = cUNOPx(pushop)->op_first;
    firstargop = pushop->op_sibling;

    for (cvop = firstargop; cvop->op_sibling; cvop = cvop->op_sibling) ;

    lastargop = pushop;
    for (
        lastargop = pushop, argop = firstargop;
        argop != cvop;
        lastargop = argop, argop = argop->op_sibling
    ) ;

    pushop->op_sibling = cvop;
    lastargop->op_sibling = NULL;
    newop = newUNOP(OP_NULL, 0, firstargop);
    newop->op_type    = OP_CUSTOM;
    newop->op_private = entersubop->op_private;
    newop->op_ppaddr  = S_pp_decode_uri_fast;

    op_free(entersubop);

    return newop;
}

#ifdef XopENTRY_set
static XOP my_xop, my_wrapop;
#endif

MODULE = URI::Escape::XS		PACKAGE = URI::Escape::XS
PROTOTYPES: ENABLE

SV *
encodeURIComponent(str)
    SV *str;
CODE:
    RETVAL = encode_uri_component(str);
OUTPUT:
    RETVAL

SV *
decodeURIComponent(str)
    SV *str;
CODE:
    RETVAL = decode_uri_component(str);
    sv_dump(RETVAL);
OUTPUT:
    RETVAL


SV *
decodeURIComponent_fast(str)
    SV *str;
CODE:
    RETVAL = decode_uri_component_fast(str);
OUTPUT:
    RETVAL

BOOT:
{
    CV * const cv = get_cvn_flags("URI::Escape::XS::decodeURIComponent_fast", 40, 0);
    cv_set_call_checker(cv, S_ck_decode_uri_fast, (SV *)cv);
#ifdef XopENTRY_set
    XopENTRY_set(&my_xop, xop_name, "decodeURIComponent_fast");
    XopENTRY_set(&my_xop, xop_desc, "decodeURIComponent_fast");
    XopENTRY_set(&my_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ S_pp_decode_uri_fast, &my_xop);
#endif /* XopENTRY_set */
}
