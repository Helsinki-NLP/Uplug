/*
 * trans.c 1990/11/12/Mon Yutaka MYOKI(Nagao Lab., KUEE)
 *
 * $Id$
 */

#include "chadic.h"

#define MRPH_WEIGHT_MAX USHRT_MAX	/* 65535 */

/*
 * strcmp_tail
 */
static int
strcmp_tail(char *s1, char *s2)
{
    int diff_len;

    diff_len = strlen(s1) - strlen(s2);

    if (diff_len >= 0)
	return strcmp(s1 + diff_len, s2);
    else
	return strcmp(s2 - diff_len, s1);
}

/*
 * print_mrph
 */
static void
print_mrph1(FILE * fp, mrph_t * mrph)
{
    fprintf(fp, "%s%c%s%c%s%c%s%c%s%c%c%c%c%c%c%c%c%c",
	    mrph->midasi, 0, mrph->yomi, 0, mrph->pron, 0,
	    mrph->base, 0, mrph->info, 0,
	    mrph->hinsi / CHAINT_SCALE + CHAINT_OFFSET,
	    mrph->hinsi % CHAINT_SCALE + CHAINT_OFFSET,
	    mrph->ktype + CHAINT_OFFSET, mrph->kform + CHAINT_OFFSET,
	    mrph->weight / CHAINT_SCALE + CHAINT_OFFSET,
	    mrph->weight % CHAINT_SCALE + CHAINT_OFFSET,
	    mrph->con_tbl / CHAINT_SCALE + CHAINT_OFFSET,
	    mrph->con_tbl % CHAINT_SCALE + CHAINT_OFFSET);
}

static void
print_mrph_comp(FILE * fp, mrph_t * mrph)
{
    for (; mrph->hinsi; mrph++)
	print_mrph1(fp, mrph);
    fputc('\n', fp);
}

static void
print_mrph_with_midasi(FILE * fp, mrph_t * mrph)
{
    print_mrph1(fp, mrph);
    print_mrph_comp(fp, mrph + 1);
}

/*
 * 見出しのない単語はすべての活用形を出力 
 */
static void
print_mrph_without_midasi(FILE * fp, mrph_t * mrph)
{
    int i;

    for (i = 1; Cha_form[mrph->ktype][i].name; i++) {
	if (!Cha_form[mrph->ktype][i].gobi[0])
	    continue;
	fprintf(fp, "%s%c%s%c%s%c%s%c%s%c%c%c%c%c%c%c%c%c",
		Cha_form[mrph->ktype][i].gobi, 0,
		Cha_form[mrph->ktype][i].ygobi, 0,
		Cha_form[mrph->ktype][i].pgobi, 0,
		mrph->base, 0, mrph->info, 0,
		mrph->hinsi / CHAINT_SCALE + CHAINT_OFFSET,
		mrph->hinsi % CHAINT_SCALE + CHAINT_OFFSET,
		mrph->ktype + CHAINT_OFFSET, i + CHAINT_OFFSET,
		mrph->weight / CHAINT_SCALE + CHAINT_OFFSET,
		mrph->weight % CHAINT_SCALE + CHAINT_OFFSET,
		(mrph->con_tbl + i - 1) / CHAINT_SCALE + CHAINT_OFFSET,
		(mrph->con_tbl + i - 1) % CHAINT_SCALE + CHAINT_OFFSET);
	print_mrph_comp(fp, mrph + 1);
    }
}

static void
print_mrph(FILE * fp, mrph_t * mrph)
{
    if (mrph->midasi[0])
	print_mrph_with_midasi(fp, mrph);
    else
	print_mrph_without_midasi(fp, mrph);
}

/*
 * trans_exit
 */
static void
trans_exit(int status, char *msg, chasen_cell_t * cell)
{
    cha_exit_file(status, "`%s' %s\n", cha_s_tostr(cell), msg);
}

/*
 * get_midasi_list
 */
static chasen_cell_t *
get_midasi_list(chasen_cell_t * x)
{
    chasen_cell_t *y;

    if (nullp(y = cha_assoc(cha_tmp_atom(JSTR_WORD), x)))
	if (nullp(y = cha_assoc(cha_tmp_atom(ESTR_WORD), x)))
	    trans_exit(1, "requires a list for midasi", x);

    return cha_cdr(y);
}

/*
 * get_midasi_str_weight
 */
static void
get_midasi_str_weight(chasen_cell_t * cell, int def_weight, mrph_t * mrph)
{
    double weight_double;
    int weight_int;
    char *midasi_str = NULL;

    if (atomp(cell)) {
	/*
	 * (見出し語 ××× ...) 
	 */
	midasi_str = s_atom_val(cell);
	mrph->weight = def_weight;
    } else if (atomp(cha_car(cell))) {
	/*
	 * (見出し語 (××× weight) ...) 
	 */
	midasi_str = s_atom_val(cha_car(cell));
	if (nullp(cha_cdr(cell)))
	    mrph->weight = (unsigned short) def_weight;
	else if (!atomp(cha_car(cha_cdr(cell))))
	    trans_exit(1, "has illegal form", cell);
	else {
	    weight_double = atof(s_atom_val(cha_car(cha_cdr(cell))));
	    weight_int = (int) (weight_double * MRPH_DEFAULT_WEIGHT);
	    if (weight_int < 0 || weight_int > MRPH_WEIGHT_MAX) {
		trans_exit(-1, ": weight must be between 0 and 6553.5",
			   cell);
		if (weight_int < 0)
		    weight_int = 0;
		if (weight_int > MRPH_WEIGHT_MAX)
		    weight_int = MRPH_WEIGHT_MAX;
	    }
	    mrph->weight = (unsigned short) weight_int;
	}
    } else {
	trans_exit(1, "has illegal form", cell);
    }

    if (strlen(midasi_str) > MIDASI_LEN)
	cha_exit_file(1, "midashi `%s' is too long", midasi_str);

    strcpy(mrph->midasi, midasi_str);
#ifdef SJIS
    sjis2euc(mrph->midasi);
#endif
}

/*
 * get_yomi
 */
static char *
get_yomi(chasen_cell_t * x)
{
    chasen_cell_t *y;
    char *s;

    if (nullp(y = cha_assoc(cha_tmp_atom(JSTR_READING), x)) &&
	nullp(y = cha_assoc(cha_tmp_atom(ESTR_READING), x)))
	return "";

    s = cha_s_atom(cha_car(cha_cdr(y)));

    if (strlen(s) > MIDASI_LEN)
	cha_exit_file(1, "yomi `%s' is too long", s);

    return s;
}

static int
get_hinsi(chasen_cell_t * x)
{
    chasen_cell_t *y;

    if (nullp(y = cha_assoc(cha_tmp_atom(JSTR_POS), x)) &&
	nullp(y = cha_assoc(cha_tmp_atom(ESTR_POS), x)))
	return 0;

    return cha_get_nhinsi_id(cha_car(cha_cdr(y)));
}

/*
 * get_ktype
 */
static int
get_ktype(chasen_cell_t * x)
{
    chasen_cell_t *y;

    if (nullp(y = cha_assoc(cha_tmp_atom(JSTR_CTYPE), x)) &&
	nullp(y = cha_assoc(cha_tmp_atom(ESTR_CTYPE), x)))
	trans_exit(1, "requires a list for conjugation type", x);

    return cha_get_type_id(cha_s_atom(cha_car(cha_cdr(y))));
}

/*
 * get_ktype
 */
static int
get_kform(chasen_cell_t * x, int ktype)
{
    chasen_cell_t *y;

    if (nullp(y = cha_assoc(cha_tmp_atom(JSTR_CFORM), x)) &&
	nullp(y = cha_assoc(cha_tmp_atom(ESTR_CFORM), x)))
	trans_exit(1, "requires a list for conjugation form", x);

    return cha_get_form_id(cha_s_atom(cha_car(cha_cdr(y))), ktype);
}

/*
 * for EDRdic '94.Mar 
 */
/*
 * get_edrconnect
 */
static chasen_cell_t *
get_edrconnect(chasen_cell_t * x)
{
    chasen_cell_t *y;

    y = cha_assoc(cha_tmp_atom(JSTR_CONN_ATTR), x);
    return cha_car(cha_cdr(y));
}

/*
 * get_info
 */
static char *
get_info(chasen_cell_t * x)
{
    chasen_cell_t *y;

    if (nullp(y = cha_assoc(cha_tmp_atom(JSTR_INFO1), x)))
	if (nullp(y = cha_assoc(cha_tmp_atom(JSTR_INFO2), x)))
	    if (nullp(y = cha_assoc(cha_tmp_atom(ESTR_INFO), x)))
		return "";

    /*
     * JUMAN2.0 では cha_cdr(y) を返すようになっていた 
     */
    return cha_s_atom(cha_car(cha_cdr(y)));
}

static char *
get_base(chasen_cell_t * x)
{
    chasen_cell_t *y;

    if (nullp(y = cha_assoc(cha_tmp_atom(JSTR_BASE), x)))
	if (nullp(y = cha_assoc(cha_tmp_atom(ESTR_BASE), x)))
	    return "";

    return cha_s_atom(cha_car(cha_cdr(y)));
}

static char *
get_pron(chasen_cell_t * x)
{
    chasen_cell_t *y;
    char *s;

    if (nullp(y = cha_assoc(cha_tmp_atom(JSTR_PRON), x)))
	if (nullp(y = cha_assoc(cha_tmp_atom(ESTR_PRON), x)))
	    return "";

    s = cha_s_atom(cha_car(cha_cdr(y)));

    if (strlen(s) > MIDASI_LEN)
	cha_exit_file(1, ": pronunciation `%s' is too long", s);

    return s;
}

/*
 * trim_midasi_gobi
 */
static void
trim_midasi_gobi(mrph_t * mrph)
{
    char *gobi;

    gobi = Cha_form[mrph->ktype][Cha_type[mrph->ktype].basic].gobi;
    if (strcmp_tail(mrph->midasi, gobi))
	cha_exit_file(1, "midashi `%s' conflicts with katsuyou form",
		      mrph->midasi);

    mrph->midasi[strlen(mrph->midasi) - strlen(gobi)] = '\0';
}

/*
 * trim_yomi_gobi
 */
static void
trim_yomi_gobi(mrph_t * mrph)
{
    char *gobi;

    if (!mrph->yomi[0])
	return;

    gobi = Cha_form[mrph->ktype][Cha_type[mrph->ktype].basic].ygobi;
    if (strcmp_tail(mrph->yomi, gobi))
	cha_exit_file(1, "yomi `%s' conflicts with katsuyou form",
		      mrph->yomi);

    mrph->yomi[strlen(mrph->yomi) - strlen(gobi)] = '\0';
}

/*
 * trim_pron_gobi
 */
static void
trim_pron_gobi(mrph_t * mrph)
{
    char *gobi;

    if (!mrph->pron[0])
	return;

    gobi = Cha_form[mrph->ktype][Cha_type[mrph->ktype].basic].pgobi;
    if (strcmp_tail(mrph->pron, gobi))
	cha_exit_file(1, "pron `%s' conflicts with katsuyou form",
		      mrph->pron);

    mrph->pron[strlen(mrph->pron) - strlen(gobi)] = '\0';
}

/*
 * trans_mrph
 */
static chasen_cell_t *
get_mrph(chasen_cell_t * block, mrph_t * mrph, int def_weight,
	 int need_kform)
{
    int katuyou;
    char *s;

    /*
     * 品詞 
     */
    mrph->hinsi = cha_get_nhinsi_id(cha_car(cha_car(block)));
    /*
     * 活用型 
     */
    katuyou = Cha_hinsi[mrph->hinsi].kt;
    if (katuyou != 1)
	mrph->ktype = mrph->kform = 0;
    else {
	mrph->ktype =
	    cha_get_type_id(cha_s_atom(cha_car(cha_cdr(cha_car(block)))));
	mrph->kform =
	    cha_get_form_id(cha_s_atom
			    (cha_car(cha_cdr(cha_cdr(cha_car(block))))),
			    mrph->ktype);
    }
    block = cha_cdr(block);

    /*
     * 見出し語 
     */
    get_midasi_str_weight(cha_car(block), def_weight, mrph);
    /*
     * 品詞・活用テーブルのチェック 
     */
    cha_check_table(mrph);
    if (katuyou == 1)
	trim_midasi_gobi(&mrph[0]);
    block = cha_cdr(block);
    /*
     * 読み 
     */
    if (strlen(s = cha_s_atom(cha_car(block))) > MIDASI_LEN)
	cha_exit_file(1, "yomi `%s' is too long", s);
    strcpy(mrph->yomi, s);
#ifdef SJIS
    sjis2euc(mrph->yomi);
#endif
    if (katuyou == 1)
	trim_yomi_gobi(mrph);
    block = cha_cdr(block);
    /*
     * 発音 
     */
    if (strlen(s = cha_s_atom(cha_car(block))) > MIDASI_LEN)
	cha_exit_file(1, "pronunciation `%s' is too long", s);
    strcpy(mrph->pron, s);
#ifdef SJIS
    sjis2euc(mrph->pron);
#endif
    if (katuyou == 1)
	trim_pron_gobi(mrph);
    block = cha_cdr(block);

    /*
     * 原形 
     */
    mrph->base = cha_s_atom(cha_car(block));
    block = cha_cdr(block);
    /*
     * 付加情報 
     */
    mrph->info = cha_s_atom(cha_car(block));
#ifdef SJIS
    sjis2euc(mrph->info);
#endif
    block = cha_cdr(block);

    return block;
}

static void
trans_mrph(chasen_cell_t * block, int def_weight, FILE * fp_out)
{
    mrph_t *mrph, mrphs[256];
    chasen_cell_t *block0 = block;

    mrph = mrphs;
    block = get_mrph(block, mrph, def_weight, 0);

    for (mrph++; !nullp(block); block = cha_cdr(block), mrph++) {
	/*
	 * 構成語の活用語は活用形が必要。ただし最後の形態素は
	 * 複合語が非活用語なら活用形は不要(あっても無視) 
	 */
	get_mrph(cha_car(block), mrph, def_weight,
		 !(nullp(cha_cdr(block)) && mrphs[0].ktype));
	mrph->weight = 0;
    }
    mrph->hinsi = 0;

    if (mrph > mrphs + 1) {
	mrphs[1].weight = mrphs[0].weight;
	if (mrphs[0].ktype && mrphs[0].ktype != mrph[-1].ktype)
	    trans_exit(1,
		       ": conjugation type is different from that of the compound word",
		       block0);
    }

    print_mrph(fp_out, mrphs);
}

/*
 * trans_word
 */
static void
get_word(chasen_cell_t * block, mrph_t * mrph, int def_weight,
	 int need_kform, int gets_midasi)
{
    int katuyou, hinsi;
    chasen_cell_t *connect_cell;	/* EDRdic '94.Mar */

    if ((hinsi = get_hinsi(block)) > 0)
	mrph->hinsi = hinsi;
    katuyou = Cha_hinsi[mrph->hinsi].kt;
    mrph->base = get_base(block);	/* 原形 */

    /*
     * 活用型 
     */
    if (katuyou != 1)
	mrph->ktype = mrph->kform = 0;
    else {
	mrph->ktype = get_ktype(block);
	if (need_kform)
	    mrph->kform = get_kform(block, mrph->ktype);
	else
	    mrph->kform = 0;
    }

    if (gets_midasi) {
	get_midasi_str_weight(cha_car(get_midasi_list(block)), def_weight,
			      mrph);
	/*
	 * 品詞・活用テーブルのチェック 
	 */
	if (nullp(connect_cell = get_edrconnect(block)))
	    cha_check_table(mrph);	/* 連接情報 */
	else
	    /* for EDRdic '94.Mar */
	    cha_check_edrtable(mrph, connect_cell);
	if (katuyou == 1)
	    trim_midasi_gobi(mrph);
    }

    strcpy(mrph->yomi, get_yomi(block));	/* 読み */
#ifdef SJIS
    sjis2euc(mrph->yomi);
#endif
    if (katuyou == 1)
	trim_yomi_gobi(mrph);

    strcpy(mrph->pron, get_pron(block));	/* 発音 */
#ifdef SJIS
    sjis2euc(mrph->pron);
#endif
    if (katuyou == 1)
	trim_pron_gobi(mrph);

    mrph->info = get_info(block);	/* 付加情報 */
#ifdef SJIS
    sjis2euc(mrph->info);
#endif
}

static void
trans_word(chasen_cell_t * block, mrph_t * mrph0, int def_weight,
	   FILE * fp_out)
{
    chasen_cell_t *midasi_list;
    mrph_t *mrph, mrphs[256];
    int def_hinsi = mrph0->hinsi;
    int katuyou;
    chasen_cell_t *connect_cell;	/* EDRdic '94.Mar */
    chasen_cell_t *cell1, *block0;

    block0 = block;
    mrph = mrphs;
    memcpy(mrphs, mrph0, sizeof(mrph_t));
    get_word(block, mrph, def_weight, 0, 0);
    mrph++;

    if (!nullp(cell1 = cha_assoc(cha_tmp_atom(JSTR_COMPOUND), block)) ||
	!nullp(cell1 = cha_assoc(cha_tmp_atom(ESTR_COMPOUND), block))) {
	block = cha_cdr(cell1);
	for (; !nullp(block); block = cha_cdr(block), mrph++) {
	    mrph->hinsi = def_hinsi;
	    /*
	     * 構成語の活用語は活用形が必要。ただし最後の形態素は
	     * 複合語が非活用語なら活用形は不要(あっても無視) 
	     */
	    get_word(cha_car(block), mrph, def_weight,
		     !(nullp(cha_cdr(block)) && mrphs[0].ktype), 1);
	    mrph->weight = 0;
	}
	if (mrphs[0].ktype && mrphs[0].ktype != mrph[-1].ktype)
	    trans_exit(1,
		       ": conjugation type is different from that of the compound word",
		       block0);
    }

    mrph->hinsi = 0;

    mrph = mrphs;
    /*
     * 見出し語 
     */
    katuyou = Cha_hinsi[mrph->hinsi].kt;
    block = block0;
    for (midasi_list = get_midasi_list(block);
	 !nullp(midasi_list); midasi_list = cha_cdr(midasi_list)) {
	get_midasi_str_weight(cha_car(midasi_list), def_weight, mrph);
	mrphs[1].weight = mrphs[0].weight;
	/*
	 * 品詞・活用テーブルのチェック 
	 */
	if (nullp(connect_cell = get_edrconnect(block)))
	    cha_check_table(mrph);	/* 連接情報 */
	else
	    /* for EDRdic '94.Mar */
	    cha_check_edrtable(mrph, connect_cell);
	if (katuyou == 1)
	    trim_midasi_gobi(mrph);

	print_mrph(fp_out, mrph);
    }
}

void
trans(FILE * fp_in, FILE * fp_out)
{
    mrph_t mrphs[2], *mrph;
    chasen_cell_t *cell;
    int hinsi, weight = MRPH_WEIGHT_MAX;

    mrph = mrphs;
    mrphs[1].hinsi = 0;
    mrph->kform = 0;
    hinsi = -1;

    while (!cha_s_feof(fp_in)) {
	cell = cha_s_read(fp_in);
	if (atomp(cell))
	    trans_exit(1, "is not list", cell);

	if (atomp(cha_car(cell))) {
	    char *s = s_atom_val(cha_car(cell));
	    if (strmatch2(s, JSTR_POS, ESTR_POS))
		hinsi = cha_get_nhinsi_id(cha_car(cha_cdr(cell)));
	    else if (strmatch2(s, JSTR_DEF_POS_COST, ESTR_DEF_POS_COST))
		weight = atoi(s_atom_val(cha_car(cha_cdr(cell))));
	    else if (strmatch2(s, JSTR_MRPH, ESTR_MRPH))
		trans_mrph(cha_cdr(cell), weight, fp_out);
	    else {
		/*
		 * upper compatible for old format 
		 */
		char *hinsi_str[256];
		char **hinsi = hinsi_str;
		for (; atomp(cha_car(cell)); cell = cha_car(cha_cdr(cell)))
		    *hinsi++ = s_atom_val(cha_car(cell));
		*hinsi = NULL;
		mrph->hinsi = cha_get_nhinsi_str_id(hinsi_str);
		trans_word(cell, mrph, weight, fp_out);
	    }
	} else {
	    if (hinsi < 0)
		cha_exit_file(1, "hinsi is not defined");
	    mrph->hinsi = hinsi;
	    trans_word(cell, mrph, weight, fp_out);
	}
	cha_s_free(cell);
    }
}
