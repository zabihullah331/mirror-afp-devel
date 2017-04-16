(*  
    Author:      René Thiemann 
                 Sebastiaan Joosten
                 Akihisa Yamada
    License:     BSD
*)
section \<open>Algebraic Numbers -- Excluding Addition and Multiplication\<close>

text \<open>This theory contains basic definition and results on algebraic numbers, namely that
  algebraic numbers are closed under negation, inversion, $n$-th roots, and
  that every rational number is algebraic. For all of these closure properties, corresponding
  polynomial witnesses are available. 

  Moreover, this theory contains the uniqueness result,
  that for every algebraic number there is exactly one content-free irreducible polynomial with
  positive leading coefficient for it.
  This result is stronger than similar ones which you find in many textbooks.
  The reason is that here we do not require a least degree construction.

  This is essential, since given some content-free irreducible polynomial for x,
  how should we check whether the degree is optimal. In the formalized result, this is
  not required. The result is proven via GCDs, and that the GCD does not change
  when executed on the rational numbers or on the reals or complex numbers, and that
  the GCD of a rational polynomial can be expressed via the GCD of integer polynomials.\<close>
  
text \<open>Many results are taken from the textbook \cite[pages 317ff]{AlgNumbers}.\<close>

theory Algebraic_Numbers_Prelim
imports
  "~~/src/HOL/Library/Fundamental_Theorem_Algebra"
  "../Polynomial_Factorization/Rational_Factorization"
  "../Berlekamp_Zassenhaus/Factorize_Rat_Poly"
begin

(* TODO: move *)
lemma content_free_imp_unit_iff:
  assumes ca: "content (a :: int poly) dvd 1"
  shows "a dvd 1 \<longleftrightarrow> degree a = 0"
proof
  assume "degree a = 0"
  from degree0_coeffs[OF this] obtain a0 where a: "a = [:a0:]" by auto
  then have "a0 dvd content a" by (simp add: content_def cCons_def)
  with ca have "a0 dvd 1" by auto
  with a show "a dvd 1" by (auto simp: poly_dvd_1)
next
  assume "a dvd 1"
  with poly_dvd_1 show "degree a = 0" by auto
qed



(* TODO: move/refine *)
lemma content_dvd_1_degree_0:
  fixes p :: "int poly"
  assumes c: "content p dvd 1" and deg: "degree p = 0"
  shows "p dvd 1"
proof-
  from deg c content_free_imp_unit_iff poly_dvd_1 have "coeff p 0 dvd 1" by blast
    then have "[:coeff p 0:] dvd 1" by (auto simp: poly_dvd_1)
    with deg have "p dvd 1" by (auto simp: degree_0_id)
    then show ?thesis by auto
qed

lemma irreducible_content:
  fixes p :: "'a::{idom,semiring_Gcd} poly"
  assumes "irreducible p" shows "degree p = 0 \<or> content p dvd 1"
proof(rule ccontr)
  assume not: "\<not>?thesis"
  from content_dvd_coeff have "content p dvd coeff p i" for i by auto
  then have "[:content p:] dvd p" by (simp add: const_poly_dvd_iff)
  then obtain r where p: "p = r * [:content p:]" by (elim dvdE, auto)
  from irreducibleD[OF assms this] have "r dvd 1 \<or> [:content p:] dvd 1" by auto
  with not have "r dvd 1" unfolding const_poly_dvd_1 by auto
  then have "degree r = 0" and "coeff r 0 dvd 1" unfolding poly_dvd_1 by auto
  with degree0_coeffs obtain r0 where r0: "r = [:r0:]" by auto
  from p[unfolded r0] have "p = [: r0 * content p :]"
    by (metis add.right_neutral mult.commute mult_pCons_left mult_zero_right pCons_0_0 smult_pCons)
  with degree_pCons_0 have "degree p = 0" by metis
  with not show False by auto
qed

(* TODO: move *)
lemma linear_irreducible_field:
  fixes p :: "'a :: field poly"
  assumes deg: "degree p = 1" shows "irreducible p"
proof (intro irreducibleI)
  from deg show p0: "p \<noteq> 0" by auto
  from deg show "\<not> p dvd 1" by (auto simp: poly_dvd_1)
  fix a b assume p: "p = a * b"
  with p0 have a0: "a \<noteq> 0" and b0: "b \<noteq> 0" by auto
  from degree_mult_eq[OF this, folded p] assms
  consider "degree a = 1" "degree b = 0" | "degree a = 0" "degree b = 1" by force
  then show "a dvd 1 \<or> b dvd 1"
    by (cases; insert a0 b0, auto intro:content_dvd_1_degree_0)
qed

(* TODO: move *)
lemma linear_irreducible_int:
  fixes p :: "int poly"
  assumes deg: "degree p = 1" and cp: "content p dvd 1"
  shows "irreducible p"
proof (intro irreducibleI)
  from deg show p0: "p \<noteq> 0" by auto
  from deg show "\<not> p dvd 1" by (auto simp: poly_dvd_1)
  fix a b assume p: "p = a * b"
  note * = cp[unfolded p is_unit_content_iff, unfolded content_mult]
  have a1: "content a dvd 1" and b1: "content b dvd 1"
    using content_ge_0_int[of a] pos_zmult_eq_1_iff_lemma[OF *] * by (auto simp: abs_mult)
  with p0 have a0: "a \<noteq> 0" and b0: "b \<noteq> 0" by auto
  from degree_mult_eq[OF this, folded p] assms
  consider "degree a = 1" "degree b = 0" | "degree a = 0" "degree b = 1" by force
  then show "a dvd 1 \<or> b dvd 1"
    by (cases; insert a1 b1, auto intro:content_dvd_1_degree_0)
qed

(* TODO: remove *)
lemma irreducible_connect_rev:
  assumes irr: "irreducible p" and deg: "degree p \<noteq> 0"
  shows "Missing_Polynomial.irreducible p"
proof(intro Missing_Polynomial.irreducibleI deg notI)
  fix q assume degq: "degree q \<noteq> 0" and diff: "degree q < degree p" and qp: "q dvd p"
  from degq have nu: "\<not> q dvd 1" by (auto simp: poly_dvd_1)
  from qp obtain r where p: "p = q * r" by (elim dvdE)
  from irreducibleD[OF irr this] nu have "r dvd 1" by auto
  then have "degree r = 0" by (auto simp: poly_dvd_1)
  with degq diff show False unfolding p using degree_mult_le[of q r] by auto
qed

subsection \<open>Polynomial Evaluation of Integer and Rational Polynomials in Fields.\<close>

abbreviation ipoly :: "int poly \<Rightarrow> 'a :: field_char_0 \<Rightarrow> 'a"
where "ipoly f x \<equiv> poly (of_int_poly f) x"

lemma poly_map_poly_code[code_unfold]: "poly (map_poly h p) x = fold_coeffs (\<lambda> a b. h a + x * b) p 0"
  by (induct p, auto)

abbreviation real_of_int_poly :: "int poly \<Rightarrow> real poly" where
  "real_of_int_poly \<equiv> of_int_poly"

abbreviation real_of_rat_poly :: "rat poly \<Rightarrow> real poly" where
  "real_of_rat_poly \<equiv> map_poly of_rat"

lemma of_rat_of_int[simp]: "of_rat \<circ> of_int = of_int" by auto

lemma ipoly_of_rat[simp]: "ipoly p (of_rat y) = of_rat (ipoly p y)"
proof-
  have id: "of_int = of_rat o of_int" unfolding comp_def by auto
  show ?thesis by (subst id, subst map_poly_map_poly[symmetric], auto)
qed

lemma ipoly_of_real[simp]: "ipoly p (of_real x) = of_real (ipoly p x)"
proof -
  have id: "of_int = of_real o of_int" unfolding comp_def by auto
  show ?thesis by (subst id, subst map_poly_map_poly[symmetric], auto)
qed


(* restating with of_int_poly *)
lemma gcd_rat_to_gcd_int: "gcd (of_int_poly f :: rat poly) (of_int_poly g) = 
  smult (inverse (of_int (lead_coeff (gcd f g)))) (of_int_poly (gcd f g))" 
by (fact gcd_rat_to_gcd_int)


lemma finite_ipoly_roots: assumes "p \<noteq> 0"
  shows "finite {x :: real. ipoly p x = 0}"
proof -
  let ?p = "real_of_int_poly p"
  from assms have "?p \<noteq> 0" by auto
  thus ?thesis by (rule poly_roots_finite)
qed

subsection \<open>Algebraic Numbers -- Definition, Inverse, and Roots\<close>

text \<open>A number @{term "x :: 'a :: field"} is algebraic iff it is the root of an integer polynomial.
  Whereas the Isabelle distribution this is defined via the embedding
  of integers in an field via @{const Ints}, we work with integer polynomials
  of type @{type int} and then use @{const ipoly} for evaluating the polynomial at
  a real or complex point.\<close>  
  
lemma algebraic_altdef_ipoly: 
  fixes x :: "'a :: field_char_0"
  shows "algebraic x \<longleftrightarrow> (\<exists>p. ipoly p x = 0 \<and> p \<noteq> 0)"
unfolding algebraic_def
proof (safe, goal_cases)
  case (1 p)
  define the_int where "the_int = (\<lambda>x::'a. THE r. x = of_int r)"
  define p' where "p' = map_poly the_int p"
  have of_int_the_int: "of_int (the_int x) = x" if "x \<in> \<int>" for x
    unfolding the_int_def by (rule sym, rule theI') (insert that, auto simp: Ints_def)
  have the_int_0_iff: "the_int x = 0 \<longleftrightarrow> x = 0" if "x \<in> \<int>"
    using of_int_the_int[OF that] by auto  
  have "map_poly of_int p' = map_poly (of_int \<circ> the_int) p"
      by (simp add: p'_def map_poly_map_poly)
  also from 1 of_int_the_int have "\<dots> = p"
    by (subst poly_eq_iff) (auto simp: coeff_map_poly)
  finally have p_p': "map_poly of_int p' = p" .
  show ?case
  proof (intro exI conjI notI)
    from 1 show "ipoly p' x = 0" by (simp add: p_p')
  next
    assume "p' = 0"
    hence "p = 0" by (simp add: p_p' [symmetric])
    with \<open>p \<noteq> 0\<close> show False by contradiction
  qed
next
  case (2 p)
  thus ?case by (intro exI[of _ "map_poly of_int p"], auto)
qed  

text \<open>Definition of being algebraic with explicit witness polynomial.\<close>

definition represents :: "int poly \<Rightarrow> 'a :: field_char_0 \<Rightarrow> bool" (infix "represents" 51)
  where "p represents x = (ipoly p x = 0 \<and> p \<noteq> 0)"

lemma representsI[intro]: "ipoly p x = 0 \<Longrightarrow> p \<noteq> 0 \<Longrightarrow> p represents x"
  unfolding represents_def by auto

lemma representsD:
  assumes "p represents x" shows "p \<noteq> 0" and "ipoly p x = 0" using assms unfolding represents_def by auto

lemma representsE[elim]:
  assumes "p represents x" and "p \<noteq> 0 \<Longrightarrow> ipoly p x = 0 \<Longrightarrow> thesis"
  shows thesis using assms unfolding represents_def by auto

lemma represents_of_rat[simp]: "p represents (of_rat x) = p represents x" by (auto elim!:representsE)
lemma represents_of_real[simp]: "p represents (of_real x) = p represents x" by (auto elim!:representsE)

lemma represents_irr_non_0:
  assumes irr: "irreducible p" and ap: "p represents x" and x0: "x \<noteq> 0"
  shows "poly p 0 \<noteq> 0"
proof
  have nu: "\<not> [:0,1::int:] dvd 1" by (auto simp: poly_dvd_1)
  assume "poly p 0 = 0"
  hence dvd: "[: 0, 1 :] dvd p" by (unfold dvd_iff_poly_eq_0, simp)
  then obtain q where pq: "p = [:0,1:] * q" by (elim dvdE)
  from irreducibleD[OF irr this] nu have "q dvd 1" by auto
  from this obtain r where "q = [:r:]" "r dvd 1" by (auto simp add: poly_dvd_1 dest: degree0_coeffs)
  with pq have "p = [:0,r:]" by auto
  with ap have "x = 0" by auto
  with x0 show False by auto
qed

text \<open>The polynomial encoding a rational number.\<close>

definition poly_rat :: "rat \<Rightarrow> int poly" where
  "poly_rat x = (case quotient_of x of (n,d) \<Rightarrow> [:-n,d:])"

definition cf_pos :: "int poly \<Rightarrow> bool" where 
  "cf_pos p = (content p = 1 \<and> lead_coeff p > 0)" 

definition cf_pos_poly :: "int poly \<Rightarrow> int poly" where
  "cf_pos_poly f = (let
      c = content f;
      d = (sgn (lead_coeff f) * c)
    in div_poly d f)"

lemma sgn_is_unit[intro!]:
  fixes x :: "'a :: linordered_idom" (* find/make better class *)
  assumes "x \<noteq> 0"
  shows "sgn x dvd 1" using assms by(cases x "0::'a" rule:linorder_cases, auto)

lemma cf_pos_poly_0[simp]: "cf_pos_poly 0 = 0" by (unfold cf_pos_poly_def div_poly_def, auto)

lemma cf_pos_poly_eq_0[simp]: "cf_pos_poly f = 0 \<longleftrightarrow> f = 0"
proof(cases "f = 0")
  case True
  thus ?thesis unfolding cf_pos_poly_def Let_def by (simp add: div_poly_def)
next
  case False
  then have lc0: "lead_coeff f \<noteq> 0" by auto
  then have s0: "sgn (lead_coeff f) \<noteq> 0" (is "?s \<noteq> 0") and "content f \<noteq> 0" (is "?c \<noteq> 0") by (auto simp: sgn_0_0)
  then have sc0: "?s * ?c \<noteq> 0" by auto
  { fix i
    from content_dvd_coeff sgn_is_unit[OF lc0]
    have "?s * ?c dvd coeff f i" by (auto simp: unit_dvd_iff)
    then have "coeff f i div (?s * ?c) = 0 \<longleftrightarrow> coeff f i = 0" by (auto simp:dvd_div_eq_0_iff)
  } note * = this
  show ?thesis unfolding cf_pos_poly_def Let_def div_poly_def poly_eq_iff by (auto simp: coeff_map_poly *)
qed

lemma
  shows cf_pos_poly_main: "smult (sgn (lead_coeff f) * content f) (cf_pos_poly f) = f" (is ?g1)
    and content_cf_pos_poly[simp]: "content (cf_pos_poly f) = (if f = 0 then 0 else 1)" (is ?g2)
    and lead_coeff_cf_pos_poly[simp]: "lead_coeff (cf_pos_poly f) > 0 \<longleftrightarrow> f \<noteq> 0" (is ?g3)
    and cf_pos_poly_dvd[simp]: "cf_pos_poly f dvd f" (is ?g4)
proof(atomize(full), (cases "f = 0"; intro conjI))
  case True
  then show ?g1 ?g2 ?g3 ?g4 by simp_all
next
  case f0: False
  let ?s = "sgn (lead_coeff f)" 
  have s: "?s \<in> {-1,1}" using f0 unfolding sgn_if by auto
  define g where "g \<equiv> smult ?s f" 
  define d where "d \<equiv> ?s * content f"
  have "content g = content ([:?s:] * f)" unfolding g_def by simp
  also have "\<dots> = content [:?s:] * content f" unfolding gauss_lemma by simp
  also have "content [:?s:] = 1" using s by (auto simp: content_def)
  finally have cg: "content g = content f" by simp
  from f0  
  have d: "cf_pos_poly f = div_poly d f"  by (auto simp: cf_pos_poly_def Let_def d_def)
  let ?g = "normalize_content g" 
  define ng where "ng = normalize_content g"
  note d
  also have "div_poly d f = div_poly (content g) g" unfolding cg unfolding g_def d_def
    by (rule poly_eqI, unfold coeff_div_poly coeff_smult, insert s, auto simp: div_minus_right)
  finally have fg: "cf_pos_poly f = normalize_content g" unfolding normalize_content_def . 
  have "lead_coeff f \<noteq> 0" using f0 by auto
  hence lg: "lead_coeff g > 0" unfolding g_def lead_coeff_smult
    by (meson linorder_neqE_linordered_idom sgn_greater sgn_less zero_less_mult_iff)
  hence g0: "g \<noteq> 0" by auto
  from f0 content_normalize_content_1[OF this]
  show ?g2 unfolding fg by auto
  from g0 have "content g \<noteq> 0" by simp
  with arg_cong[OF smult_normalize_content[of g], of lead_coeff, unfolded lead_coeff_smult]
    lg content_ge_0_int[of g] have lg': "lead_coeff ng > 0" unfolding ng_def 
    by (metis dual_order.antisym dual_order.strict_implies_order zero_less_mult_iff)
  with f0 show ?g3 unfolding fg ng_def by auto

  have d0: "d \<noteq> 0" using s f0 by (force simp add: d_def)
  have "smult d (cf_pos_poly f) = smult ?s (smult (content f) (div_poly (content f) (smult ?s f)))" 
    unfolding fg normalize_content_def cg by (simp add: g_def d_def)
  also have "div_poly (content f) (smult ?s f) = smult ?s (div_poly (content f) f)" 
    using s by (metis cg g_def normalize_content_def normalize_content_smult_int sgn_sgn)
  finally have "smult d (cf_pos_poly f) = smult (content f) (normalize_content f)" 
    unfolding normalize_content_def using s by auto
  also have "\<dots> = f" by (rule smult_normalize_content)
  finally have df: "smult d (cf_pos_poly f) = f" .
  with d0 show ?g1 by (auto simp: d_def)
  from df have *: "f = cf_pos_poly f * [:d:]" by simp
  from dvdI[OF this] show ?g4.
qed

(* TODO: remove *)
lemma irreducible_connect_int:
  fixes p :: "int poly"
  assumes ir: "Missing_Polynomial.irreducible p" and c: "content p = 1"
  shows "irreducible p"
proof(intro irreducibleI)
  note * = ir[unfolded Missing_Polynomial.irreducible_def]
  from * have p0: "p \<noteq> 0" by auto
  then show "p \<noteq> 0" by auto
  from * show "\<not> p dvd 1" unfolding poly_dvd_1 by auto
  fix a b assume p: "p = a * b"
  from c[unfolded p gauss_lemma] have cab:"content a * content b = 1" by auto
  from cab have ca: "content a dvd 1" by (intro dvdI, auto)
  from cab have cb: "content b dvd 1" by (intro dvdI, auto simp: ac_simps)
  show "a dvd 1 \<or> b dvd 1"
  proof (rule ccontr)
    assume "\<not>?thesis"
    with ca cb have deg: "degree a \<noteq> 0" "degree b \<noteq> 0" by (auto simp: content_free_imp_unit_iff)
    then have "degree p > degree a" by (unfold p, subst degree_mult_eq, auto)
    with * deg have "\<not> a dvd p" by auto
    with p show False by auto
  qed
qed

lemma
  shows ipoly_cf_pos_poly_eq_0[simp]: "ipoly (cf_pos_poly p) x = 0 \<longleftrightarrow> ipoly p x = 0"
    and degree_cf_pos_poly[simp]: "degree (cf_pos_poly p) = degree p"
    and cf_pos_cf_pos_poly[intro]: "p \<noteq> 0 \<Longrightarrow> cf_pos (cf_pos_poly p)"
proof-
  show "degree (cf_pos_poly p) = degree p"
    by (subst(3) cf_pos_poly_main[symmetric], auto simp:sgn_eq_0_iff)
  {
    assume p: "p \<noteq> 0"
    show "cf_pos (cf_pos_poly p)" using cf_pos_poly_main p by (auto simp: cf_pos_def)
    have "(ipoly (cf_pos_poly p) x = 0) = (ipoly p x = 0)"
      apply (subst(3) cf_pos_poly_main[symmetric]) by (auto simp: sgn_eq_0_iff)
  }
  then show "(ipoly (cf_pos_poly p) x = 0) = (ipoly p x = 0)" by (cases "p = 0", auto)
qed


lemma cf_pos_poly_eq_1: "cf_pos_poly f = 1 \<longleftrightarrow> degree f = 0 \<and> f \<noteq> 0" (is "?l \<longleftrightarrow> ?r")
proof(intro iffI conjI)
  assume ?r
  then have df0: "degree f = 0" and f0: "f \<noteq> 0" by auto
  from  degree0_coeffs[OF df0] obtain f0 where f: "f = [:f0:]" by auto
  show "cf_pos_poly f = 1" using f0 unfolding f cf_pos_poly_def Let_def div_poly_def
    by (auto simp: content_def mult_sgn_abs)
next
  assume l: ?l
  then have "degree (cf_pos_poly f) = 0" by auto
  then show "degree f = 0" by simp
  from l have "cf_pos_poly f \<noteq> 0" by auto
  then show "f \<noteq> 0" by simp
qed



lemma irr_cf_root_free_poly_rat[simp]: "irreducible (poly_rat x)" 
  "cf_pos (poly_rat x)" "root_free (poly_rat x)"
  "square_free (poly_rat x)"
proof -
  obtain n d where x: "quotient_of x = (n,d)" by force
  hence id: "poly_rat x = [:-n,d:]" by (auto simp: poly_rat_def)
  from quotient_of_denom_pos[OF x] have d: "d > 0" by auto
  show "root_free (poly_rat x)" unfolding id root_free_def using d by auto
  show "cf_pos (poly_rat x)" unfolding id cf_pos_def using d quotient_of_coprime[OF x]
    by (auto simp: content_def)
  from this[unfolded cf_pos_def]
  show irr: "irreducible (poly_rat x)" unfolding id using d by (auto intro!: linear_irreducible_int)
  show "square_free (poly_rat x)"
    apply (rule irreducible_square_free)
    apply (rule irreducible_connect_rev)
    apply (fact irr) unfolding id using d by auto
qed
  
lemma poly_rat[simp]: "ipoly (poly_rat x) (of_rat x :: 'a :: field_char_0) = 0" "ipoly (poly_rat x) x = 0" 
  "poly_rat x \<noteq> 0" "ipoly (poly_rat x) y = 0 \<longleftrightarrow> y = (of_rat x :: 'a)" 
proof -
  from irr_cf_root_free_poly_rat(1)[of x] show "poly_rat x \<noteq> 0" 
    unfolding irreducible_def by auto  
  obtain n d where x: "quotient_of x = (n,d)" by force
  hence id: "poly_rat x = [:-n,d:]" by (auto simp: poly_rat_def)
  from quotient_of_denom_pos[OF x] have d: "d \<noteq> 0" by auto
  have "y * of_int d = of_int n \<Longrightarrow> y = of_int n / of_int d" using d
    by (simp add: eq_divide_imp)
  with d id show "ipoly (poly_rat x) (of_rat x) = 0" "ipoly (poly_rat x) x = 0" 
    "ipoly (poly_rat x) y = 0 \<longleftrightarrow> y = (of_rat x :: 'a)"  
    by (auto simp: of_rat_minus of_rat_divide simp: quotient_of_div[OF x]) 
qed

lemma poly_rat_represents_of_rat: "(poly_rat x) represents (of_rat x)" by auto

lemma ipoly_smult_0_iff: assumes c: "c \<noteq> 0" 
  shows "(ipoly (smult c p) x = (0 :: real)) = (ipoly p x = 0)"
  using c by simp


(* TODO *)
lemma not_irreducibleD:
  assumes "\<not> irreducible x" and "x \<noteq> 0" and "\<not> x dvd 1"
  shows "\<exists>y z. x = y * z \<and> \<not> y dvd 1 \<and> \<not> z dvd 1" using assms apply (unfold irreducible_def) by auto


lemma cf_pos_poly_represents[simp]: "(cf_pos_poly p) represents x \<longleftrightarrow> p represents x"
  unfolding represents_def by auto

definition factors_of_int_poly :: "int poly \<Rightarrow> int poly list" where
  "factors_of_int_poly p = map (cf_pos_poly o fst) (snd (factorize_int_poly p))"

lemma coprime_prod: (* TODO: move *)
  "a \<noteq> 0 \<Longrightarrow> c \<noteq> 0 \<Longrightarrow> coprime (a * b) (c * d) \<Longrightarrow> coprime b (d::'a::{semiring_gcd})"
  unfolding coprime_iff_gcd_one
  by (metis coprime_lmult coprime_mul_eq' mult.commute)

lemma smult_prod: (* TODO: move or find corresponding lemma *)
  "smult a b = monom a 0 * b"
  by (simp add: monom_0)

lemma degree_map_poly_2:
  assumes "f (lead_coeff p) \<noteq> 0"
  shows   "degree (map_poly f p) = degree p"
proof (cases "p=0")
  case False thus ?thesis 
    unfolding degree_eq_length_coeffs Polynomial.coeffs_map_poly
    using assms by (simp add:coeffs_def)
qed auto

lemma degree_normalize[simp]: "degree (normalize (p :: int poly)) = degree p"
proof(cases "p=0")
  case False
  show ?thesis
    apply (unfold normalize_poly_eq_map_poly) apply (intro degree_map_poly_2)
    by (metis False div_by_0 div_normalize div_unit_factor leading_coeff_neq_0 unit_factor_eq_0_iff)
qed auto

lemma degree_of_gcd: "degree (gcd q r) \<noteq> 0 \<longleftrightarrow>
 degree (gcd (of_int_poly q :: 'a :: {field_char_0,euclidean_ring_gcd} poly) (of_int_poly r)) \<noteq> 0"
proof -
  let ?r = "of_rat :: rat \<Rightarrow> 'a" 
  interpret rpoly: field_hom' ?r 
    by (unfold_locales, auto simp: of_rat_add of_rat_mult)
  {
    fix p  
    have "of_int_poly p = map_poly (?r o of_int) p" unfolding o_def
      by auto
    also have "\<dots> = map_poly ?r (map_poly of_int p)"
      by (subst map_poly_map_poly, auto)
    finally have "of_int_poly p = map_poly ?r (map_poly of_int p)" .
  } note id = this
  show ?thesis unfolding id by (fold hom_distribs, simp add: gcd_rat_to_gcd_int)
qed

lemma irreducible_cf_pos_poly:
  assumes irr: "irreducible p" and deg: "degree p \<noteq> 0"
  shows "irreducible (cf_pos_poly p)" (is "irreducible ?p")
proof (unfold irreducible_altdef, intro conjI allI impI)
  from irr show "?p \<noteq> 0" by auto
  from deg have "degree ?p \<noteq> 0" by simp
  then show "\<not> ?p dvd 1" unfolding poly_dvd_1 by auto
  fix b assume "b dvd cf_pos_poly p"
  also note cf_pos_poly_dvd
  finally have "b dvd p".
  with irr[unfolded irreducible_altdef] have "p dvd b \<or> b dvd 1" by auto
  then show "?p dvd b \<or> b dvd 1" by (auto dest: dvd_trans[OF cf_pos_poly_dvd])
qed

lemma factors_of_int_poly:
  defines "rp \<equiv> ipoly :: int poly \<Rightarrow> 'a :: {field_char_0,euclidean_ring_gcd} \<Rightarrow> 'a"
  assumes "factors_of_int_poly p = qs"
  shows "\<And> q. q \<in> set qs \<Longrightarrow> cf_pos q \<and> irreducible q \<and> degree q \<le> degree p \<and> degree q \<noteq> 0"
  "p \<noteq> 0 \<Longrightarrow> rp p x = 0 \<longleftrightarrow> (\<exists> q \<in> set qs. rp q x = 0)"
  "p \<noteq> 0 \<Longrightarrow> rp p x = 0 \<Longrightarrow> \<exists>! q \<in> set qs. rp q x = 0"
  "distinct qs"
proof -
  obtain c qis where factt: "factorize_int_poly p = (c,qis)" by force
  from assms[unfolded factors_of_int_poly_def factt]
  have qs: "qs = map (cf_pos_poly \<circ> fst) (snd (c, qis))"  by auto
  note fact = factorize_int_poly(1)[OF factt]
  note fact_mem = factorize_int_poly(2,3)[OF factt]
  have sqf: "square_free_factorization p (c, qis)" by (rule fact(1))
  note sff = square_free_factorizationD[OF sqf]
  have sff': "p = Polynomial.smult c (\<Prod>(a, i)\<leftarrow> qis. a ^ Suc i)" 
    unfolding sff(1) prod.distinct_set_conv_list[OF sff(5)] ..
  {
    fix q
    assume q: "q \<in> set qs"
    then obtain r i where qi: "(r,i) \<in> set qis" and qr: "q = cf_pos_poly r" unfolding qs by auto
    from split_list[OF qi] obtain qis1 qis2 where qis: "qis = qis1 @ (r,i) # qis2" by auto
    have dvd: "r dvd p" unfolding sff' qis dvd_def 
      by (intro exI[of _ "smult c (r ^ i * (\<Prod>(a, i)\<leftarrow>qis1 @  qis2. a ^ Suc i))"], auto)
    from fact_mem[OF qi] have r0: "r \<noteq> 0" by auto
    from qi factt have p: "p \<noteq> 0" by (cases p, auto)
    with dvd have deg: "degree r \<le> degree p" by (metis dvd_imp_degree_le)
    with fact_mem[OF qi] r0
    show "cf_pos q \<and> irreducible q \<and> degree q \<le> degree p \<and> degree q \<noteq> 0" unfolding qr
      by (auto intro!:irreducible_cf_pos_poly)
  } note * = this
  show "distinct qs" unfolding distinct_conv_nth 
  proof (intro allI impI)
    fix i j
    assume "i < length qs" "j < length qs" and diff: "i \<noteq> j" 
    hence ij: "i < length qis" "j < length qis" 
      and id: "qs ! i = cf_pos_poly (fst (qis ! i))" "qs ! j = cf_pos_poly (fst (qis ! j))" unfolding qs by auto    
    obtain qi I where qi: "qis ! i = (qi, I)" by force
    obtain qj J where qj: "qis ! j = (qj, J)" by force    
    from sff(5)[unfolded distinct_conv_nth, rule_format, OF ij diff] qi qj 
    have diff: "(qi, I) \<noteq> (qj, J)" by auto
    from ij qi qj have "(qi, I) \<in> set qis" "(qj, J) \<in> set qis" unfolding set_conv_nth by force+
    from sff(3)[OF this diff] sff(2) this
    have cop: "coprime qi qj" "degree qi \<noteq> 0" "degree qj \<noteq> 0" by auto
    note i = cf_pos_poly_main[of qi, unfolded smult_prod monom_0]
    note j = cf_pos_poly_main[of qj, unfolded smult_prod monom_0]
    from cop(2) i have deg: "degree (qs ! i) \<noteq> 0" by (auto simp: id qi)
    have cop: "coprime (qs ! i) (qs ! j)"
      unfolding id qi qj fst_conv
      apply (rule coprime_prod[of "[:sgn (lead_coeff qi) * content qi:]" "[:sgn (lead_coeff qj) * content qj:]"])
      using cop
      unfolding i j by (auto simp: sgn_eq_0_iff)
    show "qs ! i \<noteq> qs ! j"
    proof
      assume id: "qs ! i = qs ! j" 
      have "degree (gcd (qs ! i) (qs ! j)) = degree (qs ! i)"  unfolding id by simp
      also have "\<dots> \<noteq> 0" using deg by simp
      finally show False using cop by simp
    qed
  qed
  assume p: "p \<noteq> 0"
  from fact(1) p have c: "c \<noteq> 0" using sff(1) by auto
  let ?r = "of_int :: int \<Rightarrow> 'a"
  let ?rp = "map_poly ?r"
  have rp: "\<And> x p. rp p x = 0 \<longleftrightarrow> poly (?rp p) x = 0" unfolding rp_def ..
  have "rp p x = 0 \<longleftrightarrow> rp (\<Prod>(x, y)\<leftarrow>qis. x ^ Suc y) x = 0" unfolding sff'(1)
    unfolding rp using c by simp 
  also have "\<dots> = (\<exists> (q,i) \<in>set qis. poly (?rp (q ^ Suc i)) x = 0)" 
    unfolding qs rp of_int_poly_hom.hom_prod_list poly_prod_list_zero_iff set_map by fastforce
  also have "\<dots> = (\<exists> (q,i) \<in>set qis. poly (?rp q) x = 0)"
    unfolding of_int_poly_hom.hom_power poly_power_zero_iff by auto
  also have "\<dots> = (\<exists> q \<in> fst ` set qis. poly (?rp q) x = 0)" by force
  also have "\<dots> = (\<exists> q \<in> set qs. rp q x = 0)" unfolding rp qs snd_conv o_def bex_simps set_map
    by (rule bex_cong[OF refl], simp)
  finally show iff: "rp p x = 0 \<longleftrightarrow> (\<exists> q \<in> set qs. rp q x = 0)" by auto
  assume "rp p x = 0"
  with iff obtain q where q: "q \<in> set qs" and rtq: "rp q x = 0" by auto
  then obtain i q' where qi: "(q',i) \<in> set qis" and qq': "q = cf_pos_poly q'" unfolding qs by auto  
  show "\<exists>! q \<in> set qs. rp q x = 0"
  proof (intro ex1I, intro conjI, rule q, rule rtq, clarify)
    fix r
    assume "r \<in> set qs" and rtr: "rp r x = 0"
    then obtain j r' where rj: "(r',j) \<in> set qis" and rr': "r = cf_pos_poly r'" unfolding qs by auto
    from rtr rtq have rtr: "rp r' x = 0" and rtq: "rp q' x = 0" 
      unfolding rp rr' qq' by auto
    from rtr rtq have "[:-x,1:] dvd ?rp q'" "[:-x,1:] dvd ?rp r'" unfolding rp
      by (auto simp: poly_eq_0_iff_dvd)
    hence "[:-x,1:] dvd gcd (?rp q') (?rp r')" by simp
    hence "gcd (?rp q') (?rp r') = 0 \<or> degree (gcd (?rp q') (?rp r')) \<noteq> 0"
      by (metis is_unit_iff_degree is_unit_pCons_iff one_neq_zero one_poly_def semiring_gcd_class.is_unit_gcd)
    hence "gcd q' r' = 0 \<or> degree (gcd q' r') \<noteq> 0"
      unfolding gcd_eq_0_iff degree_of_gcd[of q' r',symmetric] by auto
    hence "\<not> coprime q' r'" by auto
    with sff(3)[OF qi rj] have "q' = r'" by auto
    thus "r = q" unfolding rr' qq' by simp
  qed
qed

lemma factors_int_poly_represents:
  fixes x :: "'a :: {field_char_0,euclidean_ring_gcd}"
  assumes p: "p represents x"
shows "\<exists> q \<in> set (factors_of_int_poly p). q represents x \<and> cf_pos q \<and> irreducible q
  \<and> degree q \<le> degree p"
proof -
  from representsD[OF p] have p: "p \<noteq> 0" and rt: "ipoly p x = 0" by auto
  note fact = factors_of_int_poly[OF refl]
  from fact(2)[OF p, of x] rt obtain q where q: "q \<in> set (factors_of_int_poly p)" and 
    rt: "ipoly q x = 0" by auto
  from fact(1)[OF q] rt show ?thesis
    by (intro bexI[OF _ q], auto simp: represents_def irreducible_def)
qed

lemma smult_inverse_monom:"p \<noteq> 0 \<Longrightarrow> smult (inverse c) (p::rat poly) = 1 \<longleftrightarrow> p = [: c :]"
  proof (cases "c=0")
    case True thus "p \<noteq> 0 \<Longrightarrow> ?thesis" by auto
  next
    case False thus ?thesis by (metis left_inverse right_inverse smult_1 smult_1_left smult_smult)
  qed

lemma of_int_monom:"of_int_poly p = [:rat_of_int c:] \<longleftrightarrow> p = [: c :]" by (induct p, auto)

lemma degree_0_content:
  fixes p :: "int poly"
  assumes deg: "degree p = 0" shows "content p = abs (coeff p 0)"
proof-
  from deg obtain a where p: "p = [:a:]" by (auto dest: degree0_coeffs)
  show ?thesis by (auto simp: p)
qed

lemma irreducible_cf_pos_gcd: 
  assumes ir:"irreducible p" and pm:"cf_pos p"
  shows "gcd p q \<in> {1,p}"
proof (cases "degree p = 0")
  case True
  then obtain a where p: "p = [:a:]" by (auto dest: degree0_coeffs)
  from ir pm[unfolded cf_pos_def True]
  show ?thesis unfolding p by auto
next
  case deg: False
  let ?c = "inverse (rat_of_int (lead_coeff p))"
  let ?p = "smult ?c (of_int_poly p)"
  let ?cg = "inverse (rat_of_int (lead_coeff (gcd p q)))"
  have "yun_wrel q 1 (of_int_poly q)" by (auto simp:yun_wrel_def)
  have p0: "p \<noteq> 0" using ir by (auto simp:irreducible_def)
  hence c0:"?c \<noteq> 0" by auto
  have yun:"yun_rel p (rat_of_int (lead_coeff p)) ?p"
           "yun_wrel q 1 (of_int_poly q)" "1 \<noteq> (0::rat)"
           using p0 pm by (auto simp:yun_wrel_def yun_rel_def cf_pos_def)
  have "rat_of_int (lead_coeff (gcd p q)) \<noteq> 0" using p0 by auto
  hence yun_gcd:"gcd ?p (of_int_poly q) = smult ?cg (of_int_poly (gcd p q))"
           "content (gcd p q) = 1" "0 < lead_coeff (gcd p q)"
  using yun_rel_gcd[OF yun refl,unfolded yun_rel_def yun_wrel_def] by auto
  { fix q :: "rat poly"
    assume deg:"degree q \<noteq> 0"
    hence "q \<noteq> 0" by auto
    then obtain c q' where q': "q = smult c (of_int_poly q')" "content q' = 1" "degree q' = degree q"
      using rat_to_normalized_int_poly[of q] by(cases "rat_to_normalized_int_poly q",blast)
    assume dvd:"q dvd of_int_poly p"
    from smult_dvd_cancel[OF this[unfolded q']] q'(2-) dvd_poly_int_content_1[OF q'(2),of p]
    have "\<exists> q'. degree q' = degree q \<and> q' dvd p"  by auto
  }
  with irreducible_connect_rev[OF ir deg]
  have "Missing_Polynomial.irreducible (of_int_poly p::rat poly)"
    unfolding Missing_Polynomial.irreducible_def by force
  hence ir:"Missing_Polynomial.irreducible ?p" by(subst irreducible_smult,auto simp:p0)
  have pm':"monic ?p" "content p = 1" using pm[unfolded cf_pos_def] by auto
  note gcd_tangled = monic_irreducible_gcd[OF pm'(1) ir,of "of_int_poly q"]
  from gcd_tangled p0 have o0:"of_int_poly (gcd p q) \<noteq> (0::rat poly)" by auto
  have c1:"gcd p q = [:lead_coeff (gcd p q):] \<Longrightarrow> coprime p q"
    using content_const[of "lead_coeff (gcd p q)"] yun_gcd(2,3) by simp
  consider (1) "Polynomial.smult ?cg (of_int_poly (gcd p q)) = 1"
         | (p) "Polynomial.smult ?cg (of_int_poly (gcd p q)) = ?p"
    using gcd_tangled[unfolded yun_gcd(1)] by auto
  thus ?thesis proof(cases)
    case 1
    with c1 show ?thesis by (auto simp:smult_inverse_monom[OF o0] of_int_monom)
  next
    case p
    have "yun_rel p (rat_of_int (lead_coeff p)) (gcd ?p (of_int_poly q))"
      using yun(1)[unfolded] yun_gcd(1)[unfolded p] by auto
    from yun_rel_same_right[OF yun_rel_gcd[OF yun(1,2) one_neq_zero refl] this]
    show ?thesis by auto
  qed
qed

lemma irreducible_cf_pos_gcd_twice: 
  assumes p: "irreducible p" "cf_pos p" 
  and q: "irreducible q" "cf_pos q"
  shows "gcd p q = 1 \<or> p = q"
proof (cases "gcd p q = 1")
  case False note pq = this
  have id: "gcd p q = gcd q p" by (simp add: gcd.commute)
  have "p = gcd p q" using irreducible_cf_pos_gcd[OF p] pq by force
  also have "\<dots> = q" using irreducible_cf_pos_gcd[OF q] pq unfolding id by force
  finally show ?thesis by auto
qed simp

interpretation of_rat_hom: field_hom_0' of_rat..

lemma represents_irreducible_unique: 
  fixes x :: "'a :: {field_char_0,euclidean_ring_gcd}"
  assumes "algebraic x"
  shows "\<exists>! p. p represents x \<and> cf_pos p \<and> irreducible p"
proof -
  let ?p = "\<lambda> p. p represents x \<and> cf_pos p \<and> irreducible p"
  note irrD = irreducibleD
  from assms obtain p where
    "p represents x" unfolding algebraic_altdef_ipoly represents_def by auto
  from factors_int_poly_represents[OF this] obtain p where
    p: "?p p" by auto
  show ?thesis
  proof (rule ex1I)
    show "?p p" by fact
    fix q
    assume q: "?p q"
    show "q = p" 
    proof (rule ccontr)
      let ?rp = "map_poly of_int :: int poly \<Rightarrow> 'a poly"
      let ?ri = "map_poly of_int :: int poly \<Rightarrow> rat poly" 
      let ?rr = "map_poly of_rat :: rat poly \<Rightarrow> 'a poly" 
      have rpi: "?rp p = ?rr (?ri p)" for p
        by (subst map_poly_map_poly, auto simp: o_def)
      assume "q \<noteq> p"
      with irreducible_cf_pos_gcd_twice[of p q] p q have gcd: "gcd p q = 1" by auto
      from p q have rt: "ipoly p x = 0" "ipoly q x = 0" unfolding represents_def by auto
      define c where "c = inverse (rat_of_int (lead_coeff (gcd p q)))" 
      have rt: "poly (?rp p) x = 0" "poly (?rp q) x = 0" using rt by auto
      hence "[:-x,1:] dvd ?rp p" "[:-x,1:] dvd ?rp q" 
        unfolding poly_eq_0_iff_dvd by auto
      hence "[:-x,1:] dvd gcd (?rp p) (?rp q)" by (rule gcd_greatest)
      also have "\<dots> = ?rr (gcd (?ri p) (?ri q))" unfolding rpi
        by (rule of_rat_hom.map_poly_gcd [symmetric])
      also have "gcd (?ri p) (?ri q) = smult c (?ri (gcd p q))" unfolding gcd_rat_to_gcd_int c_def ..
      also have "?ri (gcd p q) = 1" by (simp add: gcd)
      also have "?rr (smult c 1) = [: of_rat c :]" by simp
      finally show False using c_def gcd by (simp add: dvd_iff_poly_eq_0)
    qed
  qed
qed

lemma algebraic_alg_irr_polyE:
  assumes "algebraic (x::'a::{field_char_0,euclidean_ring_gcd})"
      and "(\<And> p. p represents x \<Longrightarrow> irreducible p \<Longrightarrow> cf_pos p \<Longrightarrow> P)"
  shows "P"
proof -
  from represents_irreducible_unique[OF assms(1)]
  obtain p where "p represents x" by auto
  from factors_int_poly_represents[OF this]
  obtain p where 1: "p represents x" and 2: "irreducible p" and 3: "cf_pos p" by auto
  from assms(2)[OF 1 2 3] show P by auto
qed

lemma ipoly_poly_compose: "ipoly (p \<circ>\<^sub>p q) x = ipoly p (ipoly q x)"
proof (induct p)
  case (pCons a p)
  have "ipoly ((pCons a p) \<circ>\<^sub>p q) x = of_int a + ipoly (q * p \<circ>\<^sub>p q) x" by simp
  also have "ipoly (q * p \<circ>\<^sub>p q) x = ipoly q x * ipoly (p \<circ>\<^sub>p q) x" by simp
  also have "ipoly (p \<circ>\<^sub>p q) x = ipoly p (ipoly q x)" unfolding pCons(2) ..
  also have "of_int a + ipoly q x * \<dots> = ipoly (pCons a p) (ipoly q x)"
    unfolding map_poly_pCons[OF pCons(1)] by simp
  finally show ?case .
qed simp

text \<open>Polynomial for unary minus.\<close>  
definition poly_uminus :: "'a :: {idom,ring_char_0} poly \<Rightarrow> 'a poly" where
  "poly_uminus p = p \<circ>\<^sub>p [:0,-1:]"

lemma degree_poly_uminus[simp]: "degree (poly_uminus p) = degree p"
  unfolding poly_uminus_def by simp

lemma ipoly_uminus[simp]: "ipoly (poly_uminus p) x = ipoly p (-x)"
  unfolding poly_uminus_def ipoly_poly_compose by simp

lemma poly_uminus_0[simp]: "poly_uminus p = 0 \<longleftrightarrow> p = 0"
  unfolding poly_uminus_def 
  by (rule pcompose_eq_0, auto)

lemma represents_uminus: assumes alg: "p represents x"
  shows "(poly_uminus p) represents (-x)"
proof -
  from representsD[OF alg] have "p \<noteq> 0" and rp: "ipoly p x = 0" by auto
  hence 0: "poly_uminus p \<noteq> 0" by simp
  show ?thesis
    by (rule representsI[OF _ 0], insert rp, auto)
qed


text \<open>Polynomial for multiplicative inverse.\<close>  
definition poly_inverse :: "'a :: idom poly \<Rightarrow> 'a poly" where
  [code del]: "poly_inverse p = (\<Sum> i \<le> degree p. monom (coeff p (degree p - i)) i)"

lemma poly_inverse_rev_coeffs[code]: 
  "poly_inverse p = poly_of_list (rev (coeffs p))"
proof (cases "p = 0")
  case True
  thus ?thesis by (auto simp: poly_inverse_def)
next
  case False
  show ?thesis unfolding poly_of_list_def poly_eq_iff
  proof 
    fix n
    have "coeff (poly_inverse p) n = (if n \<le> degree p then coeff p (degree p - n) else 0)"
      unfolding poly_inverse_def coeff_sum coeff_monom
      by (cases "n \<le> degree p", auto, subst sum.remove[of _ n], auto)
    also have "\<dots> = coeff (Poly (rev (coeffs p))) n"
      unfolding poly_inverse_def coeff_sum coeff_monom coeff_Poly
      by (cases "n < length (coeffs p)", 
        auto simp: nth_default_def length_coeffs_degree[OF False], subst rev_nth,
        auto simp: length_coeffs_degree[OF False] coeffs_nth[OF False])
    finally show "coeff (poly_inverse p) n = coeff (Poly (rev (coeffs p))) n" .
  qed
qed  

lemma degree_poly_inverse_le: "degree (poly_inverse p) \<le> degree p"
  unfolding poly_inverse_def 
  by (rule degree_sum_le, force, rule order_trans[OF degree_monom_le], auto)

lemma inverse_pow_minus: assumes "x \<noteq> (0 :: 'a :: field)"
  and "i \<le> n"
  shows "inverse x ^ n * x ^ i = inverse x ^ (n - i)" 
  using assms by (simp add: field_class.field_divide_inverse power_diff power_inverse)

lemma poly_inverse: assumes x: "x \<noteq> (0 :: 'a :: field)"
  shows "poly (poly_inverse p) x = x ^ (degree p) * poly p (inverse x)" (is "?l = ?r")
proof -
  from poly_as_sum_of_monoms[of p]
  have id: "poly p (inverse x) = poly ((\<Sum>x\<le>degree p. monom (coeff p x) x)) (inverse x)" by simp
  let ?f = "\<lambda> k. poly (monom (coeff p (degree p - k)) k) x"
  have "?l = (\<Sum>k\<le>degree p. ?f k)"
    unfolding poly_inverse_def poly_sum by simp 
  also have "\<dots> = (\<Sum>k \<le> degree p. ?f (degree p - k))"
    by (subst sum.reindex_cong[of "\<lambda> i. degree p - i" "{..degree p}"], auto simp: inj_on_def)
     (metis (full_types) atMost_iff diff_diff_cancel diff_le_mono2 diff_zero image_iff le0)
  also have "\<dots> = (\<Sum>k\<le>degree p. x ^ degree p * poly (monom (coeff p k) k) (inverse x))"
    using inverse_pow_minus[OF nonzero_imp_inverse_nonzero[OF x]] by (intro sum.cong, auto simp: poly_monom)
  also have "\<dots> = ?r"
    unfolding id poly_sum sum_distrib_left by simp
  finally show ?thesis .
qed

lemma (in inj_idom_hom) poly_inverse_hom:
  "poly_inverse (map_poly hom p) = map_poly hom (poly_inverse p)"
proof -
  interpret mh: map_poly_inj_idom_hom hom..
  show ?thesis unfolding poly_inverse_def degree_map_poly by auto
qed


lemma ipoly_inverse: assumes x: "(x :: 'a :: field_char_0) \<noteq> 0" 
  shows "ipoly (poly_inverse p) x = x ^ (degree p) * ipoly p (inverse x)" (is "?l = ?r")
proof -
  let ?or = "of_int :: int \<Rightarrow> 'a"
  have hom: "inj_idom_hom ?or" ..
  show ?thesis
    using poly_inverse[OF x, of "map_poly ?or p"] by (simp add: inj_idom_hom.poly_inverse_hom[OF hom])
qed

lemma poly_inverse_0[simp]: "poly_inverse p = 0 \<longleftrightarrow> p = 0"
  unfolding poly_inverse_def 
  by (subst sum_monom_0_iff, force+)

lemma represents_inverse: assumes x: "x \<noteq> 0"
  and alg: "p represents x"
  shows "(poly_inverse p) represents (inverse x)"
proof (intro representsI)
  from representsD[OF alg] have "p \<noteq> 0" and rp: "ipoly p x = 0" by auto
  then show "poly_inverse p \<noteq> 0" by simp
  show "ipoly (poly_inverse p) (inverse x) = 0" by (subst ipoly_inverse, insert x, auto simp:rp)
qed

lemma inverse_roots: assumes x: "(x :: 'a :: field_char_0) \<noteq> 0"
  shows "ipoly (poly_inverse p) x = 0 \<longleftrightarrow> ipoly p (inverse x) = 0"
  using x by (auto simp: ipoly_inverse)

context
  fixes n :: nat
begin
text \<open>Polynomial for n-th root.\<close>  
  
definition poly_nth_root :: "'a :: idom poly \<Rightarrow> 'a poly" where
  "poly_nth_root p = p \<circ>\<^sub>p monom 1 n"

lemma ipoly_nth_root:  "ipoly (poly_nth_root p) x = ipoly p (x ^ n)"
  unfolding poly_nth_root_def ipoly_poly_compose by (simp add: map_poly_monom poly_monom)

context
  assumes n: "n \<noteq> 0"
begin
lemma poly_nth_root_0[simp]: "poly_nth_root p = 0 \<longleftrightarrow> p = 0"
  unfolding poly_nth_root_def
  by (rule pcompose_eq_0, insert n, auto simp: degree_monom_eq)

lemma represents_nth_root:
  assumes y: "y^n = x" and alg: "p represents x"
  shows "(poly_nth_root p) represents y"
proof -
  from representsD[OF alg] have "p \<noteq> 0" and rp: "ipoly p x = 0" by auto
  hence 0: "poly_nth_root p \<noteq> 0" by simp
  show ?thesis
    by (rule representsI[OF _ 0], unfold ipoly_nth_root y rp, simp)
qed

lemma represents_nth_root_odd_real:
  assumes alg: "p represents x" and odd: "odd n"
  shows "(poly_nth_root p) represents (root n x)"
  by (rule represents_nth_root[OF odd_real_root_pow[OF odd] alg])

lemma represents_nth_root_pos_real:
  assumes alg: "p represents x" and pos: "x > 0"
  shows "(poly_nth_root p) represents (root n x)"
proof -
  from n have id: "Suc (n - 1) = n" by auto
  show ?thesis
  proof (rule represents_nth_root[OF _ alg])
    show "root n x ^ n = x" using id pos by auto  
  qed
qed

lemma represents_nth_root_neg_real:
  assumes alg: "p represents x" and neg: "x < 0"
  shows "(poly_uminus (poly_nth_root (poly_uminus p))) represents (root n x)"
proof -
  have rt: "root n x = - root n (-x)" unfolding real_root_minus by simp
  show ?thesis unfolding rt 
    by (rule represents_uminus[OF represents_nth_root_pos_real[OF represents_uminus[OF alg]]], insert neg, auto)
qed
end
end

lemma represents_csqrt:
  assumes alg: "p represents x" shows "(poly_nth_root 2 p) represents (csqrt x)"
  by (rule represents_nth_root[OF _ _ alg], auto)

lemma represents_sqrt:
  assumes alg: "p represents x" and pos: "x \<ge> 0"
  shows "(poly_nth_root 2 p) represents (sqrt x)"
  by (rule represents_nth_root[OF _ _ alg], insert pos, auto)

lemma represents_degree:
  assumes "p represents x" shows "degree p \<noteq> 0"
proof 
  assume "degree p = 0"
  from degree0_coeffs[OF this] obtain c where p: "p = [:c:]" by auto
  from assms[unfolded represents_def p]
  show False by auto
qed

lemma poly_uminus_inv[simp]: "poly_uminus (poly_uminus p) = p"
  unfolding poly_uminus_def
  by (rule poly_ext, simp add: poly_pcompose)
 
text \<open>Polynomial for multiplying a rational number with an algebraic number.\<close>  

definition poly_mult_rat_main where 
  "poly_mult_rat_main n d (f :: 'a :: idom poly) = (let fs = coeffs f; k = length fs in 
    poly_of_list (map (\<lambda> (fi, i). fi * d ^ i * n ^ (k - Suc i)) (zip fs [0 ..< k])))"

definition poly_mult_rat :: "rat \<Rightarrow> int poly \<Rightarrow> int poly" where
  "poly_mult_rat r p \<equiv> case quotient_of r of (n,d) \<Rightarrow> poly_mult_rat_main n d p"

lemma coeff_poly_mult_rat_main: "coeff (poly_mult_rat_main n d f) i = coeff f i * n ^ (degree f - i) * d ^ i" 
proof -
  have id: "coeff (poly_mult_rat_main n d f) i = (coeff f i * d ^ i) * n ^ (length (coeffs f) - Suc i)"
    unfolding poly_mult_rat_main_def Let_def poly_of_list_def coeff_Poly   
    unfolding nth_default_coeffs_eq[symmetric] 
    unfolding nth_default_def by auto
  show ?thesis unfolding id by (simp add: degree_eq_length_coeffs)
qed

lemma degree_poly_mult_rat_main: "n \<noteq> 0 \<Longrightarrow> degree (poly_mult_rat_main n d f) = (if d = 0 then 0 else degree f)" 
proof (cases "d = 0")
  case True
  thus ?thesis unfolding degree_def unfolding coeff_poly_mult_rat_main by simp
next
  case False
  hence id: "(d = 0) = False" by simp
  show "n \<noteq> 0 \<Longrightarrow> ?thesis" unfolding degree_def coeff_poly_mult_rat_main id
    by (simp add: id)
qed

lemma ipoly_mult_rat_main:
  assumes "d \<noteq> 0" and "n \<noteq> 0" 
  shows "ipoly (poly_mult_rat_main n d p) x = of_int n ^ degree p * ipoly p (x * of_int d / of_int n)" 
proof -
  from assms have d: "(if d = 0 then t else f) = f" for t f :: 'b by simp
  show ?thesis
    unfolding poly_altdef of_int_hom.coeff_map_poly_hom mult.assoc[symmetric] of_int_mult[symmetric] 
      sum_distrib_left 
    unfolding of_int_hom.degree_map_poly degree_poly_mult_rat_main[OF assms(2)] d
  proof (rule sum.cong[OF refl])
    fix i
    assume "i \<in> {..degree p}" 
    hence i: "i \<le> degree p" by auto
    hence id: "of_int n ^ (degree p - i) = (of_int n ^ degree p / of_int n ^ i :: 'a)"
      by (simp add: assms(2) power_diff)
    thus "of_int (coeff (poly_mult_rat_main n d p) i) * x ^ i = of_int n ^ degree p * of_int (coeff p i) * (x * of_int d / of_int n) ^ i"
      unfolding coeff_poly_mult_rat_main
      by (simp add: field_simps)
  qed
qed

lemma degree_poly_mult_rat[simp]: assumes "r \<noteq> 0" shows "degree (poly_mult_rat r p) = degree p"
proof -
  obtain n d where quot: "quotient_of r = (n,d)" by force
  from quotient_of_div[OF quot] have r: "r = of_int n / of_int d" by auto
  from quotient_of_denom_pos[OF quot] have d: "d \<noteq> 0" by auto
  with assms r have n0: "n \<noteq> 0" by simp
  from quot have id: "poly_mult_rat r p = poly_mult_rat_main n d p"  unfolding poly_mult_rat_def by simp
  show ?thesis unfolding id degree_poly_mult_rat_main[OF n0] using d by simp
qed

lemma ipoly_mult_rat:
  assumes r0: "r \<noteq> 0"
  shows "ipoly (poly_mult_rat r p) x = of_int (fst (quotient_of r)) ^ degree p * ipoly p (x * inverse (of_rat r))"
proof -
  obtain n d where quot: "quotient_of r = (n,d)" by force
  from quotient_of_div[OF quot] have r: "r = of_int n / of_int d" by auto
  from quotient_of_denom_pos[OF quot] have d: "d \<noteq> 0" by auto
  from r r0 have n: "n \<noteq> 0" by simp
  from r d n have inv: "of_int d / of_int n = inverse r" by simp
  from quot have id: "poly_mult_rat r p = poly_mult_rat_main n d p"  unfolding poly_mult_rat_def by simp
  show ?thesis unfolding id ipoly_mult_rat_main[OF d n] quot fst_conv of_rat_inverse[symmetric] inv[symmetric]
    by (simp add: of_rat_divide)
qed

lemma poly_mult_rat_main_0[simp]:
  assumes "n \<noteq> 0" "d \<noteq> 0" shows "poly_mult_rat_main n d p = 0 \<longleftrightarrow> p = 0" 
proof 
  assume "p = 0" thus "poly_mult_rat_main n d p = 0" 
    by (simp add: poly_mult_rat_main_def)
next
  assume 0: "poly_mult_rat_main n d p = 0" 
  {
    fix i
    from 0 have "coeff (poly_mult_rat_main n d p) i = 0" by simp
    hence "coeff p i = 0" unfolding coeff_poly_mult_rat_main using assms by simp
  }
  thus "p = 0" by (intro poly_eqI, auto)
qed


lemma poly_mult_rat_0[simp]: assumes r0: "r \<noteq> 0" shows "poly_mult_rat r p = 0 \<longleftrightarrow> p = 0"
proof -
  obtain n d where quot: "quotient_of r = (n,d)" by force
  from quotient_of_div[OF quot] have r: "r = of_int n / of_int d" by auto
  from quotient_of_denom_pos[OF quot] have d: "d \<noteq> 0" by auto
  from r r0 have n: "n \<noteq> 0" by simp
  from quot have id: "poly_mult_rat r p = poly_mult_rat_main n d p"  unfolding poly_mult_rat_def by simp
  show ?thesis unfolding id using n d by simp
qed

lemma represents_mult_rat:
  assumes r: "r \<noteq> 0" and "p represents x" shows "(poly_mult_rat r p) represents (of_rat r * x)"
  using assms
  unfolding represents_def ipoly_mult_rat[OF r] by (simp add: field_simps)

text \<open>Polynomial for adding a rational number on an algebraic number.
  Again, we do not have to factor afterwards.\<close>  

definition poly_add_rat :: "rat \<Rightarrow> int poly \<Rightarrow> int poly" where
  "poly_add_rat r p \<equiv> case quotient_of r of (n,d) \<Rightarrow> 
     (poly_mult_rat_main d 1 p \<circ>\<^sub>p [:-n,d:])"

lemma poly_add_rat_code[code]: "poly_add_rat r p \<equiv> case quotient_of r of (n,d) \<Rightarrow> 
     let p' = (let fs = coeffs p; k = length fs in poly_of_list (map (\<lambda>(fi, i). fi * d ^ (k - Suc i)) (zip fs [0..<k])));
         p'' = p' \<circ>\<^sub>p [:-n,d:]
      in p''" 
  unfolding poly_add_rat_def poly_mult_rat_main_def Let_def by simp

lemma degree_poly_add_rat[simp]: "degree (poly_add_rat r p) = degree p"
proof -
  obtain n d where quot: "quotient_of r = (n,d)" by force
  from quotient_of_div[OF quot] have r: "r = of_int n / of_int d" by auto
  from quotient_of_denom_pos[OF quot] have d: "d \<noteq> 0" "d > 0" by auto
  show ?thesis unfolding poly_add_rat_def quot split
    by (simp add: degree_poly_mult_rat_main d)
qed

lemma ipoly_add_rat: "ipoly (poly_add_rat r p) x = (of_int (snd (quotient_of r)) ^ degree p) * ipoly p (x - of_rat r)" 
proof -
  obtain n d where quot: "quotient_of r = (n,d)" by force
  from quotient_of_div[OF quot] have r: "r = of_int n / of_int d" by auto
  from quotient_of_denom_pos[OF quot] have d: "d \<noteq> 0" "d > 0" by auto
  have id: "ipoly [:- n, 1:] (x / of_int d :: 'a) = - of_int n + x / of_int d" by simp
  show ?thesis unfolding poly_add_rat_def quot split
    by (simp add: ipoly_mult_rat_main ipoly_poly_compose d r degree_poly_mult_rat_main field_simps id of_rat_divide)
qed

lemma poly_add_rat_0[simp]: "poly_add_rat r p = 0 \<longleftrightarrow> p = 0"
proof -
  obtain n d where quot: "quotient_of r = (n,d)" by force
  from quotient_of_div[OF quot] have r: "r = of_int n / of_int d" by auto
  from quotient_of_denom_pos[OF quot] have d: "d \<noteq> 0" "d > 0" by auto
  show ?thesis unfolding poly_add_rat_def quot split
    by (simp add: d pcompose_eq_0)
qed

lemma add_rat_roots: "ipoly (poly_add_rat r p) x = 0 \<longleftrightarrow> ipoly p (x - of_rat r) = 0"
  unfolding ipoly_add_rat using quotient_of_nonzero by auto

lemma add_rat_represents:
  assumes "p represents x" shows "(poly_add_rat r p) represents (of_rat r + x)"
  using assms unfolding represents_def ipoly_add_rat by simp

(* TODO: move? *)
lemmas pos_mult[simplified,simp] = mult_less_cancel_left_pos[of _ 0] mult_less_cancel_left_pos[of _ _ 0]

lemma ipoly_add_rat_pos_neg:
  "ipoly (poly_add_rat r p) (x::'a::linordered_field) < 0 \<longleftrightarrow> ipoly p (x - of_rat r) < 0"
  "ipoly (poly_add_rat r p) (x::'a::linordered_field) > 0 \<longleftrightarrow> ipoly p (x - of_rat r) > 0"
  using quotient_of_nonzero unfolding ipoly_add_rat by auto

lemma sgn_ipoly_add_rat[simp]:
  "sgn (ipoly (poly_add_rat r p) (x::'a::linordered_field)) = sgn (ipoly p (x - of_rat r))" (is "sgn ?l = sgn ?r")
  using ipoly_add_rat_pos_neg[of r p x]
  by (cases ?r "0::'a" rule: linorder_cases,auto simp:  sgn_1_pos sgn_1_neg sgn_eq_0_iff)


lemma irreducible_preservation:
  fixes x :: "'a :: {field_char_0,euclidean_ring_gcd}"
  assumes irr: "irreducible p" 
  and x: "p represents x"
  and y: "q represents y"
  and deg: "degree p \<ge> degree q"
  and f: "\<And> q. q represents y \<Longrightarrow> (f q) represents x \<and> degree (f q) \<le> degree q"
  and cf: "content q = 1"
  shows "irreducible q"
proof (rule ccontr)
  define pp where "pp = cf_pos_poly p" 
  have dp: "degree p \<noteq> 0" using x by (rule represents_degree)
  have dq: "degree q \<noteq> 0" using y by (rule represents_degree)
  from cf_pos_poly_main[of p] x deg irreducible_cf_pos_poly[OF irr dp]
  have irr: "irreducible pp" and x: "pp represents x" and 
    deg: "degree pp \<ge> degree q" and cf_pos: "cf_pos pp" unfolding represents_def pp_def by auto
  from x have ax: "algebraic x" unfolding algebraic_altdef_ipoly represents_def by blast
  assume "\<not> ?thesis"
  from this irreducible_connect_int[of q] cf have "\<not> Missing_Polynomial.irreducible q" by auto
  from this[unfolded Missing_Polynomial.irreducible_def] dq obtain r where 
    r: "degree r \<noteq> 0" "degree r < degree q" and "r dvd q" by auto
  then obtain rr where q: "q = r * rr" unfolding dvd_def by auto
  have "degree q = degree r + degree rr" using dq unfolding q
    by (subst degree_mult_eq, auto)
  with r have rr: "degree rr \<noteq> 0" "degree rr < degree q" by auto
  from representsD(2)[OF y, unfolded q] 
  have "ipoly r y = 0 \<or> ipoly rr y = 0" by auto
  with r rr have "r represents y \<or> rr represents y" unfolding represents_def by auto
  with r rr obtain r where r: "r represents y" "degree r < degree q" by blast
  from f[OF r(1)] deg r(2) obtain r where r: "r represents x" "degree r < degree pp" by auto
  from factors_int_poly_represents[OF r(1)] r(2) obtain r where 
    r: "r represents x" "irreducible r" "cf_pos r" and deg: "degree r < degree pp" by force
  from represents_irreducible_unique[OF ax] r irr cf_pos x have "r = pp" by auto
  with deg show False by auto
qed
  
lemma deg_nonzero_represents:
  assumes deg: "degree p \<noteq> 0" shows "\<exists> x :: complex. p represents x"
proof -
  let ?p = "of_int_poly p :: complex poly"
  from fundamental_theorem_algebra_factorized[of ?p]
  obtain as c where id: "smult c (\<Prod>a\<leftarrow>as. [:- a, 1:]) = ?p" 
    and len: "length as = degree ?p" by blast
  have "degree ?p = degree p" by simp
  with deg len obtain b bs where as: "as = b # bs" by (cases as, auto)
  have "p represents b" unfolding represents_def id[symmetric] as using deg by auto
  thus ?thesis by blast
qed

declare irreducible_const_poly_iff [simp]

lemma poly_uminus_irreducible:
  assumes p: "irreducible (p :: int poly)" and deg: "degree p \<noteq> 0"
  shows "irreducible (cf_pos_poly (poly_uminus p))"
proof-
  from deg_nonzero_represents[OF deg] obtain x :: complex where x: "p represents x" by auto
  from represents_uminus[OF x]
  have y: "cf_pos_poly (poly_uminus p) represents (- x)" by simp
  show ?thesis
  proof (rule irreducible_preservation[OF p x y], force)
    fix q
    assume "q represents (- x)"
    from represents_uminus[OF this] have "(poly_uminus q) represents x" by simp
    thus "(poly_uminus q) represents x \<and> degree (poly_uminus q) \<le> degree q" by auto
  qed (insert p, auto)
qed

lemma poly_inverse_irreducible:
  fixes x :: "'a :: {field_char_0,euclidean_ring_gcd}"
  assumes p: "irreducible p" and x: "p represents x" and x0: "x \<noteq> 0"
  shows "irreducible (cf_pos_poly (poly_inverse p))"
proof -
  from represents_inverse[OF x0 x]
  have y: "cf_pos_poly (poly_inverse p) represents (inverse x)" by simp
  from x0 have ix0: "inverse x \<noteq> 0" by auto
  show ?thesis
  proof (rule irreducible_preservation[OF p x y])
    fix q
    assume "q represents (inverse x)"
    from represents_inverse[OF ix0 this] have "(poly_inverse q) represents x" by simp
    with degree_poly_inverse_le
    show "(poly_inverse q) represents x \<and> degree (poly_inverse q) \<le> degree q" by auto
  qed (insert p, auto simp: degree_poly_inverse_le)
qed

lemma poly_add_rat_irreducible:
  assumes p: "irreducible p" and deg: "degree p \<noteq> 0"
  shows "irreducible (cf_pos_poly (poly_add_rat r p))"
proof -
  from deg_nonzero_represents[OF deg] obtain x :: complex where x: "p represents x" by auto
  from add_rat_represents[OF x]
  have y: "cf_pos_poly (poly_add_rat r p) represents (of_rat r + x)" by simp
  show ?thesis
  proof (rule irreducible_preservation[OF p x y], force)
    fix q
    assume "q represents (of_rat r + x)"
    from add_rat_represents[OF this, of "- r"] have "(poly_add_rat (- r) q) represents x" by (simp add: of_rat_minus)
    thus "(poly_add_rat (- r) q) represents x \<and> degree (poly_add_rat (- r) q) \<le> degree q" by auto
  qed (insert p, auto)
qed

lemma poly_mult_rat_irreducible:
  assumes p: "irreducible p" and deg: "degree p \<noteq> 0" and r: "r \<noteq> 0"
  shows "irreducible (cf_pos_poly (poly_mult_rat r p))"
proof -
  from deg_nonzero_represents[OF deg] obtain x :: complex where x: "p represents x" by auto
  from represents_mult_rat[OF r x]
  have y: "cf_pos_poly (poly_mult_rat r p) represents (of_rat r * x)" by simp
  show ?thesis
  proof (rule irreducible_preservation[OF p x y], force simp: r)
    fix q
    from r have r': "inverse r \<noteq> 0" by simp
    assume "q represents (of_rat r * x)"
    from represents_mult_rat[OF r' this] have "(poly_mult_rat (inverse r) q) represents x" using r 
      by (simp add: of_rat_divide field_simps)
    thus "(poly_mult_rat (inverse r) q) represents x \<and> degree (poly_mult_rat (inverse r) q) \<le> degree q" 
      using r by auto
  qed (insert p r, auto)
qed

end
