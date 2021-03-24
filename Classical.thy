theory Classical
  imports Main
begin

type_synonym 'a domain_end = \<open>'a rel\<close>

abbreviation (input) comp_domain :: "'a domain_end \<Rightarrow> 'a domain_end \<Rightarrow> 'a domain_end" where
  "comp_domain a b \<equiv> b O a"

lemma comp_domain_assoc: "comp_domain (comp_domain a b) c = comp_domain a (comp_domain b c)"
  by auto

(* TODO: category laws *)

type_synonym ('a,'b) maps_hom = \<open>'a domain_end \<Rightarrow> 'b domain_end\<close>
definition maps_hom :: \<open>('a,'b) maps_hom \<Rightarrow> bool\<close> where
  \<open>maps_hom F \<longleftrightarrow> (\<exists>R. F = Image R)\<close>

lemma id_maps_hom: \<open>maps_hom id\<close>
  unfolding maps_hom_def
  by (metis Image_Id eq_id_iff)

definition rel_of_maps_hom :: \<open>('a,'b) maps_hom \<Rightarrow> (('a\<times>'a)\<times>('b\<times>'b)) set\<close> where
  \<open>rel_of_maps_hom F = (SOME R. F = Image R)\<close>

lemma rel_of_maps_hom: \<open>maps_hom F \<Longrightarrow> F = Image (rel_of_maps_hom F)\<close>
  unfolding maps_hom_def rel_of_maps_hom_def
  by (metis (mono_tags) someI_ex)

lemma maps_hom_mono: "maps_hom F \<Longrightarrow> mono F"
  by (auto simp: maps_hom_def mono_def Image_def)

lemma comp_maps_hom: "maps_hom F \<Longrightarrow> maps_hom G \<Longrightarrow> maps_hom (G \<circ> F)"
  unfolding maps_hom_def apply auto
  apply (rule_tac x=\<open>R O Ra\<close> in exI)
  by (auto simp: o_def)

lemma converse_hom: \<open>maps_hom converse\<close>
  unfolding maps_hom_def
  apply (rule exI[where x=\<open>{((x,y),(y,x))| x y. True}\<close>])
  by (auto simp: converse_def Image_def)

type_synonym ('a,'b,'c) maps_2hom = \<open>'a domain_end \<Rightarrow> 'b domain_end \<Rightarrow> 'c domain_end\<close>

definition maps_2hom :: "('a, 'b, 'c) maps_2hom \<Rightarrow> bool" where
  \<open>maps_2hom F2 \<longleftrightarrow> (\<exists>R2. \<forall>a b. F2 a b = R2 `` (a \<times> b))\<close>

definition rel_of_maps_2hom :: \<open>('a,'b,'c) maps_2hom \<Rightarrow> ((('a\<times>'a) \<times> ('b\<times>'b)) \<times> ('c\<times>'c)) set\<close> where
  \<open>rel_of_maps_2hom F2 = (SOME R2. \<forall>a b. F2 a b = R2 `` (a \<times> b))\<close>

lemma rel_of_maps_2hom: \<open>maps_2hom F2 \<Longrightarrow> F2 a b = rel_of_maps_2hom F2 `` (a \<times> b)\<close>
  unfolding rel_of_maps_2hom_def maps_2hom_def
  apply (rule someI2_ex)
  by auto

definition rel_prod :: "('a*'b) set => ('c*'d) set => (('a*'c) * ('b*'d)) set" where
  "rel_prod a b = (\<lambda>((a,b),(c,d)). ((a,c),(b,d))) ` (a \<times> b)"

lemma rel_prod_comp: \<open>rel_prod a b O rel_prod c d = rel_prod (a O c) (b O d)\<close>
  apply (auto simp: rel_prod_def relcomp_def relcompp_apply case_prod_beta image_def
      simp flip: Collect_case_prod)
  by force

lemma rel_prod_converse: \<open>(rel_prod a b)\<inverse> = rel_prod (a\<inverse>) (b\<inverse>)\<close>
  apply (auto simp: rel_prod_def converse_unfold image_def case_prod_beta)
  by force

lemma rel_prod_Id[simp]: "rel_prod Id Id = Id"
  by (auto simp: rel_prod_def Id_def case_prod_beta image_def)

lemma maps_hom_2hom_comp: \<open>maps_2hom F2 \<Longrightarrow> maps_hom G \<Longrightarrow> maps_2hom (\<lambda>a b. G (F2 a b))\<close>
  unfolding maps_2hom_def maps_hom_def apply auto 
  apply (rule_tac x=\<open>R2 O R\<close> in exI)
  by auto
lemma maps_2hom_hom_comp1: \<open>maps_2hom F2 \<Longrightarrow> maps_hom G \<Longrightarrow> maps_2hom (\<lambda>a b. F2 (G a) b)\<close>
  unfolding maps_2hom_def maps_hom_def apply auto 
  apply (rule_tac x=\<open>rel_prod R Id O R2\<close> in exI)
  apply (auto simp: rel_prod_def case_prod_beta)
  apply fastforce by blast

lemma maps_2hom_sym: \<open>maps_2hom F2 \<Longrightarrow> maps_2hom (\<lambda>a b. F2 b a)\<close> 
  unfolding maps_2hom_def maps_hom_def apply auto 
  apply (rule_tac x=\<open>(\<lambda>((a,b),c). ((b,a),c)) ` R2\<close> in exI)
  apply (auto simp: case_prod_beta Image_def)
  apply fastforce by blast

lemma maps_2hom_left: \<open>maps_2hom F2 \<Longrightarrow> maps_hom (\<lambda>a. F2 a b)\<close>
  using [[show_types]]
  unfolding maps_2hom_def maps_hom_def apply auto 
  apply (rule_tac x=\<open>{(a',c')| a' b' c'. ((a',b'),c') \<in> R2 \<and> b' \<in> b}\<close> in exI)
  by fastforce

lemma comp_2hom: "maps_2hom comp_domain"
  using [[show_types]]
  unfolding maps_2hom_def
  apply (rule_tac x=\<open>{((a',b'),c')| a' b' c'. fst a' = snd b' \<and> fst c' = fst b' \<and> snd c' = snd a'}\<close> in exI)
  by auto


abbreviation (input) tensor_maps :: \<open>'a domain_end \<Rightarrow> 'b domain_end \<Rightarrow> ('a\<times>'b) domain_end\<close> where
  \<open>tensor_maps \<equiv> rel_prod\<close>


lemma tensor_2hom: \<open>maps_2hom tensor_maps\<close> 
  unfolding maps_2hom_def[abs_def]
  apply (rule exI[of _ \<open>{(((ax,ay),(bx,by)), ((ax,bx),(ay,by)))| ax ay bx by. True} :: ((('a \<times> 'a) \<times> 'b \<times> 'b) \<times> ('a \<times> 'b) \<times> 'a \<times> 'b) set\<close>])
  apply (auto simp: rel_prod_def image_def case_prod_beta)
  by force

definition tensor_lift :: \<open>('a, 'b, 'c) maps_2hom
                            \<Rightarrow> (('a\<times>'b, 'c) maps_hom)\<close>
  where "tensor_lift F2 ab = {(cx,cy)| cx cy ax ay bx by. ((ax,bx),(ay,by)) \<in> ab
             \<and> (((ax,ay), (bx,by)), (cx,cy)) \<in> rel_of_maps_2hom F2}"

lemma tensor_lift_hom: 
  assumes "maps_2hom F2"
  shows "maps_hom (tensor_lift F2)"
proof -
  define R2 where "R2 = rel_of_maps_2hom F2"
  from assms
  have R2: "F2 a b = R2 `` (a \<times> b)" for a b
    by (simp add: R2_def rel_of_maps_2hom)
  define R where \<open>R = {(((ax, bx), (ay, by)), (cx, cy))| ax bx ay by cx cy. (((ax, ay), (bx, by)), (cx, cy)) \<in> R2}\<close>
  have \<open>tensor_lift F2 = (``) R\<close>
   unfolding tensor_lift_def R2_def[symmetric]
   using R_def by blast
  then show ?thesis
    unfolding maps_hom_def by auto
qed

lemma tensor_existence: 
  assumes \<open>maps_2hom F2\<close>
  shows \<open>(\<lambda>a b. tensor_lift F2 (tensor_maps a b)) = F2\<close>
proof (intro ext)
  fix a :: \<open>('a\<times>'a) set\<close> and b :: \<open>('b\<times>'b) set\<close>
  define R2 where \<open>R2 = rel_of_maps_2hom F2\<close>
  then have F2R2: "F2 a b = R2 `` (a \<times> b)" for a b
    using rel_of_maps_2hom assms by metis
  show \<open>tensor_lift F2 (Classical.rel_prod a b) = F2 a b\<close>
  proof (intro set_eqI, case_tac x, rename_tac x y, hypsubst, rule iffI)
    fix x y :: 'c
    assume "(x, y) \<in> F2 a b"
    then have xyR2: \<open>(x,y) \<in> R2 `` (a \<times> b)\<close>
      using F2R2 by auto
    then show \<open>(x, y) \<in> tensor_lift F2 (tensor_maps a b)\<close>
      unfolding tensor_lift_def R2_def[symmetric]
      apply (auto simp: rel_prod_def case_prod_beta image_def)
      by (meson fst_eqD snd_eqD)
  next
    fix x y :: 'c
    assume \<open>(x, y) \<in> tensor_lift F2 (tensor_maps a b)\<close>
    then have \<open>(x, y) \<in> R2 `` (a \<times> b)\<close>
      unfolding tensor_lift_def R2_def[symmetric]
      by (auto simp: rel_prod_def case_prod_beta image_def)
    then show \<open>(x, y) \<in> F2 a b\<close>
      using F2R2 by auto
  qed
qed

lemma tensor_ext:
  assumes \<open>maps_hom F\<close>
  assumes \<open>maps_hom G\<close>
  assumes \<open>\<And>a b. F (tensor_maps a b) = G (tensor_maps a b)\<close>
  shows "F = G"
proof -
  define RF RG where "RF = rel_of_maps_hom F" and "RG = rel_of_maps_hom G"
  then have RF: "F = Image RF" and RG: "G = Image RG"
    using rel_of_maps_hom assms by auto
  with assms have RFRG: "RF `` tensor_maps a b = RG `` tensor_maps a b" for a b
    by auto
  have "RF = RG"
  proof (rule set_eqI)
    fix v :: \<open>(('a \<times> 'b) \<times> ('a \<times> 'b)) \<times> ('c \<times> 'c)\<close>
    obtain ax bx ay "by" c where v: "v = (((ax,bx),(ay,by)),c)"
      apply atomize_elim
      by (metis surj_pair)
    have \<open>v \<in> RF \<longleftrightarrow> (((ax,bx),(ay,by)),c) \<in> RF\<close>
      using v by simp
    also have \<open>\<dots> \<longleftrightarrow> c \<in> RF `` tensor_maps {(ax,ay)} {(bx,by)}\<close>
      unfolding rel_prod_def by simp
    also have \<open>\<dots> \<longleftrightarrow> c \<in> RG `` tensor_maps {(ax,ay)} {(bx,by)}\<close>
      by (simp add: RFRG)
    also have \<open>\<dots> \<longleftrightarrow> (((ax,bx),(ay,by)),c) \<in> RG\<close>
      unfolding rel_prod_def by simp
    also have \<open>\<dots> \<longleftrightarrow> v \<in> RG\<close>
      using v by simp
    finally show \<open>v \<in> RF \<longleftrightarrow> v \<in> RG\<close>
      by -
  qed
  then show \<open>F = G\<close>
    using RF RG by simp
qed

lemma tensor_uniqueness:
  assumes \<open>maps_2hom F2\<close>
  assumes \<open>maps_hom F\<close>
  assumes \<open>(\<lambda>a b. F (tensor_maps a b)) = F2\<close>
  shows \<open>F = tensor_lift F2\<close>
  using tensor_ext tensor_existence assms
  by (metis tensor_lift_hom)


definition assoc :: \<open>(('a\<times>'b)\<times>'c, 'a\<times>('b\<times>'c)) maps_hom\<close> where 
  \<open>assoc r = {((a,(b,c)), ((a,b),c))| a b c. True} O r O {(((a,b),c), (a,(b,c)))| a b c. True}\<close>

lemma assoc_hom: \<open>maps_hom assoc\<close>
proof -
  let ?assoc = \<open>assoc :: (('a\<times>'b)\<times>'c, 'a\<times>('b\<times>'c)) maps_hom\<close>
  term \<open>rel_of_maps_hom ?assoc\<close>
  define R :: \<open>(((('a\<times>'b)\<times>'c) \<times> (('a\<times>'b)\<times>'c)) \<times> ('a\<times>('b\<times>'c)) \<times> ('a\<times>('b\<times>'c))) set\<close>
    where \<open>R = {((((ax,bx),cx), ((ay,by),cy)), (ax,(bx,cx)), (ay,(by,cy)))| ax ay bx by cx cy. True}\<close>
  have "?assoc = Image R"
    apply (rule ext)
    by (auto simp: R_def assoc_def Image_def relcomp_def relcompp_apply)
  then show \<open>maps_hom ?assoc\<close>
    using maps_hom_def by auto
qed

lemma assoc_apply: \<open>assoc (tensor_maps (tensor_maps a b) c) = (tensor_maps a (tensor_maps b c))\<close>
  unfolding assoc_def rel_prod_def
  apply (auto simp: case_prod_beta image_def relcomp_def relcompp_apply)
  by (metis fst_conv snd_conv)+

definition lvalue :: \<open>('a,'b) maps_hom \<Rightarrow> bool\<close> where
  \<open>lvalue F \<longleftrightarrow> maps_hom F \<and> (\<forall>a a'. F a O F a' = F (a O a')) \<and> F Id = Id \<and> (\<forall>a. F (a\<inverse>) = (F a)\<inverse>)\<close>

lemma
  lvalue_hom: "lvalue F \<Longrightarrow> maps_hom F"
  by (simp add: lvalue_def) 

lemma
  lvalue_comp: "lvalue F \<Longrightarrow> lvalue G \<Longrightarrow> lvalue (G \<circ> F)"  
  for F :: "('a,'b) maps_hom" and G :: "('b,'c) maps_hom"
  by (simp add: comp_maps_hom lvalue_def) 

lemma
  lvalue_mult: "lvalue F \<Longrightarrow> F (comp_domain a b) = comp_domain (F a) (F b)"
  by (simp add: lvalue_def)

lemma pair_lvalue_axiom: 
  assumes \<open>lvalue F\<close>
  assumes \<open>lvalue G\<close>
  assumes [simp]: \<open>maps_hom p\<close>
  assumes compat: \<open>\<And>a b. comp_domain (F a) (G b) = comp_domain (G b) (F a)\<close>
  assumes ptensor: \<open>\<And>a b. p (tensor_maps a b) = comp_domain (F a) (G b)\<close>
  shows \<open>lvalue p\<close>
proof (unfold lvalue_def, intro conjI allI)
  from assms show \<open>maps_hom p\<close> by -
  have h1: \<open>maps_hom (\<lambda>a. p a O p a')\<close> for a'
    apply (rule maps_2hom_left)
    apply (rule maps_2hom_hom_comp1)
    using comp_2hom maps_2hom_sym by auto
  have h2: \<open>maps_hom (\<lambda>a. p (a O a'))\<close> for a'
    apply (rule maps_2hom_left)
    apply (rule maps_hom_2hom_comp[where G=p])
    using comp_2hom maps_2hom_sym by auto
  have h3: \<open>maps_hom (\<lambda>a'. p a O p a')\<close> for a
    apply (rule maps_2hom_left)
    apply (rule maps_2hom_hom_comp1)
    using comp_2hom maps_2hom_sym by auto
  have h4: \<open>maps_hom (\<lambda>a'. p (a O a'))\<close> for a
    apply (rule maps_2hom_left)
    apply (rule maps_hom_2hom_comp[where G=p])
    using comp_2hom maps_2hom_sym by auto
  have h5: \<open>maps_hom (\<lambda>a. p (a\<inverse>))\<close>
    apply (rule comp_maps_hom[where G=p, unfolded o_def])
    by (simp_all add: converse_hom)
  have h6: \<open>maps_hom (\<lambda>a. (p a)\<inverse>)\<close>
    apply (rule comp_maps_hom[where F=p, unfolded o_def])
    by (simp_all add: converse_hom)
  have \<open>p (tensor_maps a1 a2) O p (tensor_maps a1' a2') = p ((tensor_maps a1 a2) O (tensor_maps a1' a2'))\<close> for a1 a2 a1' a2'
    unfolding ptensor rel_prod_comp
    by (metis assms(1) assms(2) comp_domain_assoc lvalue_mult compat) 
  
  then have \<open>p (tensor_maps a1 a2) O p a' = p ((tensor_maps a1 a2) O a')\<close> for a1 a2 a'
    by (rule tensor_ext[OF h3 h4, THEN fun_cong])
  then show \<open>p a O p a' = p (a O a')\<close> for a a'
    by (rule tensor_ext[OF h1 h2, THEN fun_cong])

  show \<open>p Id = Id\<close>
    apply (simp flip: rel_prod_Id add: ptensor)
    by (metis R_O_Id assms(1) assms(2) lvalue_def)
  
  have \<open>p ((tensor_maps a1 a2)\<inverse>) = (p (tensor_maps a1 a2))\<inverse>\<close> for a1 a2
    apply (simp add: ptensor converse_relcomp rel_prod_converse)
    apply (subst compat)
    by (metis assms(1) assms(2) lvalue_def)

  then show \<open>p (a\<inverse>) = (p a)\<inverse>\<close> for a
    by (rule tensor_ext[OF h5 h6, THEN fun_cong])
qed



bundle lvalue_notation begin
notation comp_domain (infixl "\<circ>\<^sub>d" 55)
notation tensor_maps (infixr "\<otimes>" 70)
end

bundle no_lvalue_notation begin
no_notation comp_domain (infixl "\<circ>\<^sub>d" 55)
no_notation tensor_maps (infixr "\<otimes>" 70)
end

end
