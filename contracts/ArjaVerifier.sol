//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );

/*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
    }
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}
contract ArjaVerifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = Pairing.G2Point(
            [4252822878758300859123897981450591353533073413197771768651442665752259397132,
             6375614351688725206403948262868962793625744043794305715222011528459656738731],
            [21847035105528745403288232691147584728191162732299865338377159692350059136679,
             10505242626370262277552901082094356697409835680220590971873171140371331206856]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [2070425343110624240009350841897249610233920953182609910628950667387138882384,
             14734547442249771881686222172344495095553678196064151044143490595315212914382],
            [17339052811671246097597982353748229096734056364800127889855806974269581527555,
             1147712211657393713741840962770741808387642091228846663105246210838448510202]
        );
        vk.IC = new Pairing.G1Point[](65);
        
        vk.IC[0] = Pairing.G1Point( 
            17494935010492745694162590734364880806041033615710320187094694446604636578540,
            18181642572685590778283621182283079571643647748343555111800584711990093369580
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            7497864167399104238238643901862810714582146801219278099736689287353820149167,
            19779732184613679481265669827668692873766600800008116349917188290771312454628
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            13349892440952327710313189473086938750342405856459692059482676414174034242499,
            5988253253975642373095332408202549661939391033135172405129805976576452262294
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            8052014114722487295248508426613223497191168549125371379396767847164460172460,
            12413882576350183495872393675639678522656829120362582790738991236186934600336
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            2000108128720098899476202853257920429702306881645388404053943113409874398154,
            1070563348496293849256915252323934910274871055939320470365679927833421103532
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            19050824221032891592445501981802590099340040722900413930606745494095792477664,
            10880583626534887328212367323588808264111609761443036882432347935257413940382
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            2600886505682776918582414061340148796675201719188699890987245350077738569511,
            14873233964039127760970016799501164550350784262628566945645525145777740674683
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            15207370695743083881073790476786775506806780271221723166914382083731677971985,
            1758182255049261103410835028540614397877296141076170069491499731864341315908
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            8589883205274148161882308373477701257539830328376962273953824612744457463047,
            21287906619891769408321970323940969379598016290508461466945155130225704618089
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            11727771568093555709211300035985990347574314988592549738935178026220842145969,
            14807466378576746372269797265048957386221440870759428545865695239981922192404
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            1955222406457763811464985665472948300342072246539607276639957820794716047504,
            5097926526724131989166788463859601247538920076389067437012636281125573150941
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            20175307347151539343009861415317474435566465295376394976545323806926905154747,
            3332376306106393192841535799538585648429813510471330116849998998595634476405
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            18900331500565484235581897695791806994390664479407765284672877293535027087302,
            16367268624216516657370479199499701666507454816982490431725343517850382638319
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            15017579915714419295859499287628492699425878635983112785328294905737950997239,
            10888248267245626735141488780701993164877053545966811659430819817093359974547
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            13463261484421842289439556747922437345225156529286622497174607891144494429074,
            17111212802410223010718553514243387573699185147862381205922673762271923849206
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            20070097368161085087767316205935821490959632422342665329117899147702430032708,
            5173830196805003694194266610758123601200422199305146494809598481719767458055
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            7965427311853869568504378304012225643816917953862521180130766526831703366941,
            11945145478926901741867260661530100817807859414583172877686549425786729236821
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            8542703443136621691926790986335702397149031877744718787727202747146658024836,
            17146694438362642812909834412860153852362487572695361087170094959266721912450
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            12392130226373115991931588564292277328423410476721768356430821006245887367868,
            10914570669464016578070276512388770255271080526082511973814531770094701732634
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            1253356981289748468804207383246281195763825943688184505241526334343051593086,
            1934409370088499655394656274308702259232867401856462728121312027672746435801
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            20516874645842774414384630271258775031124772034045683018925885995477207667610,
            5268028611571497985263134446673700612689574773634624682806161428386068964956
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            11886833267106110638330177468743903185014439889983880780420187447226352285042,
            7174600829696313141141689578759237004665243654756001132168493474721533872979
        );                                      
        
        vk.IC[22] = Pairing.G1Point( 
            707022979002699322037976955615754331924960728070768906948658931775016819146,
            3638959122316775269828473323953775830474886549509802825529930345844139365210
        );                                      
        
        vk.IC[23] = Pairing.G1Point( 
            16150288686068931382387332273901140535515328234252668035566409602216865935245,
            738881741001183101520984228092096968047692278370034607529001756915755535272
        );                                      
        
        vk.IC[24] = Pairing.G1Point( 
            13724080264038725555694499764381274232900411668817341690222480508562850994325,
            17698101898798653583168147450356008733529077895245743089944476981003503456546
        );                                      
        
        vk.IC[25] = Pairing.G1Point( 
            2350281717500546648263952112000640232657739268485767056011828569196954726994,
            14760522805358311400123763312865118526959552859547219713535451722006598782548
        );                                      
        
        vk.IC[26] = Pairing.G1Point( 
            16635619724770523080861980450946240614786997401831206742012589484485996083085,
            4647502378719185791571165273403209038653178530699724855410673814293390365659
        );                                      
        
        vk.IC[27] = Pairing.G1Point( 
            19614308912045212853916205188462624417895893142712943606099658098503614279406,
            6613402001885802705325308265848318321960991439739810970539625460460292079465
        );                                      
        
        vk.IC[28] = Pairing.G1Point( 
            11742901456858522380428060359874169759614877459150396796699942438733519381532,
            1053341488958198247949852694257895057760153056888536344799044528225522490860
        );                                      
        
        vk.IC[29] = Pairing.G1Point( 
            3294483973420070423536106826222354974634483484679636805511809624045419397022,
            829545617984594509367680317122594086592521288847671990205959438602518320923
        );                                      
        
        vk.IC[30] = Pairing.G1Point( 
            8475718300985438728796273425223965212543200660458657347109396541503803214450,
            8587386895304595943719793049443403753805607085070194890256773246717317712532
        );                                      
        
        vk.IC[31] = Pairing.G1Point( 
            10727171889488400742423098502652489059980305882425022900960084502727969861033,
            1160098207254816062231158349980608210329992743707305207235118218177698785773
        );                                      
        
        vk.IC[32] = Pairing.G1Point( 
            17978146155410276499809069526607335401245377998264769923509124347168116375105,
            16544058111852204068522229890762772406910354535314313607648391189908454580136
        );                                      
        
        vk.IC[33] = Pairing.G1Point( 
            14378748802515292883596743713110474246483797398797556432539845287760620690350,
            6682842218554421087375293767705084182832474453730998298697888875538255883782
        );                                      
        
        vk.IC[34] = Pairing.G1Point( 
            9355869097318543496651566285115024105944997349745043532881420367709527477837,
            6091750599277953546205340733226376176342790397115913696442918250020832348196
        );                                      
        
        vk.IC[35] = Pairing.G1Point( 
            12749071720648040178060196671783722630275714068479373121201087549360626590675,
            17583463262303480393970528666131137762841508741624184508347190649808779766605
        );                                      
        
        vk.IC[36] = Pairing.G1Point( 
            6444289446948446814490586943531161107288267183978316258621426279335342827856,
            9079772785707395654029467542955036670200632668732999363411256997895496516685
        );                                      
        
        vk.IC[37] = Pairing.G1Point( 
            17018630657086449201395642354298057478553825310225938480818350302955581875190,
            21250721621565451671573133279474755708161161826212654295106590319100430375279
        );                                      
        
        vk.IC[38] = Pairing.G1Point( 
            5236521743839872079086857400269413592343983660701149531486836056932612937776,
            10456462083203598403062301385680071300393248896026072313418850171415033144973
        );                                      
        
        vk.IC[39] = Pairing.G1Point( 
            7232115782550441435073341157006049075320291940412289749372493181215354780963,
            21571878969508330864834335671363824728741896331084399452764297040911859593355
        );                                      
        
        vk.IC[40] = Pairing.G1Point( 
            11041578389379062387242469892438223242471941528473508434674118513320658718497,
            13641119992620570335931877970812942624608671627546768273396709278624348803358
        );                                      
        
        vk.IC[41] = Pairing.G1Point( 
            13825529831407489858332142660368559266238405744200218936940468014475870644980,
            8884028206322269187175101125621600678218161565067672741702309864101729551609
        );                                      
        
        vk.IC[42] = Pairing.G1Point( 
            6325880205568372298005172512160365743408343845907415041212762656523124598672,
            11372690206957571478363638586938434485400926773636719302667685972591976960286
        );                                      
        
        vk.IC[43] = Pairing.G1Point( 
            16729699843920581387872616101821365867532138418264670459996233626111231823432,
            13446487626056333735383378964961638965894471141846540442436417719551151987103
        );                                      
        
        vk.IC[44] = Pairing.G1Point( 
            3910560319679928859550286993756371890146778039850625517960031776809916943984,
            1326359141882240063128824814832037630482197036834174095786605087539751894362
        );                                      
        
        vk.IC[45] = Pairing.G1Point( 
            17003847202670527381336153242318825465175076032983392996698477633173333280841,
            6677678754071766366630247419909294481211714825012822959198899800767590638117
        );                                      
        
        vk.IC[46] = Pairing.G1Point( 
            9930464046769927631153954289444891322064330214030192162297809614938124652238,
            12936280820396469277127101792642970251831063749239016583537186252361025167316
        );                                      
        
        vk.IC[47] = Pairing.G1Point( 
            7673191237313542423571327854860316218685261609998892910833978691417675788454,
            10384825163135114679480518672852635441220727769374744167725073518665695167279
        );                                      
        
        vk.IC[48] = Pairing.G1Point( 
            9367090142453101655597774883193014467563734528621086310412608553852896478192,
            12737809500925914341678099117593512182312877404813878612065663023292923035109
        );                                      
        
        vk.IC[49] = Pairing.G1Point( 
            1706479020355369354818940665489917327728355246194350675634325366647524272087,
            15853868436691037307818616154816179034742555773322129935336491965694883285783
        );                                      
        
        vk.IC[50] = Pairing.G1Point( 
            4469432547919881937380335394292074523157159494235983671669877528810539667400,
            17628230874997718347911930495999001498494186593031550989094943906118391123202
        );                                      
        
        vk.IC[51] = Pairing.G1Point( 
            17741999295773733214678689160305200489435771631940545208861344521977609416304,
            151661893279223071581523487805090348584565172067394263148609216291734229034
        );                                      
        
        vk.IC[52] = Pairing.G1Point( 
            11177483632168448791888376489787510084605717527592764677203657359806136858185,
            21526997799452806502256181382324832228090241058793269764649209503704387302918
        );                                      
        
        vk.IC[53] = Pairing.G1Point( 
            8313664661189318977881030093019176614991339683940475351789620451598067618173,
            4437008414231965231331094021281302342317914406804326776225892317883486078787
        );                                      
        
        vk.IC[54] = Pairing.G1Point( 
            5647712383134678298077148877046182527068134227203881839046414390686890641462,
            5598674601066837919057894547083973586546056412265106585640942443584585509389
        );                                      
        
        vk.IC[55] = Pairing.G1Point( 
            11584599558187602321816973368491210687727085429924111582689269915057888142998,
            16534181815041397861455715863635880789997692240224720731367399065376539960474
        );                                      
        
        vk.IC[56] = Pairing.G1Point( 
            13043064327370350578399027046161723196548600687679844545894713531829291390215,
            3265263096961344615969122793166798227115958784176715390950166054592299489472
        );                                      
        
        vk.IC[57] = Pairing.G1Point( 
            2562520035186702517602906674564473063480160116754813599827127384220147352391,
            7423707151992760108551765005252282181472435201891164518617020962326561203465
        );                                      
        
        vk.IC[58] = Pairing.G1Point( 
            7201023006070546519466432267389647699982915129241299274850920865971220331213,
            12022774000669946100778828983085715778085557200966178746454416777807799148413
        );                                      
        
        vk.IC[59] = Pairing.G1Point( 
            813912370687337694468124548382238108161068274675442582638013725996983337059,
            14717203271993308212967923528862489006494919296164997846013057828229670506345
        );                                      
        
        vk.IC[60] = Pairing.G1Point( 
            2926049059657427653369813237051062963163941980564326455906500660666585493396,
            5053264755623851061972231349331469822808977784508837312595565127376190863109
        );                                      
        
        vk.IC[61] = Pairing.G1Point( 
            17158492493266801264321751704072771279483092390207702125581194222580220920611,
            19731057710147341732659043719458799232236361330402826242371191978664733101887
        );                                      
        
        vk.IC[62] = Pairing.G1Point( 
            16176895308510636011326139254078706565140149351061427233838103837385587411885,
            7390103238608459650699708836342788735952678154139406353661775366093136320833
        );                                      
        
        vk.IC[63] = Pairing.G1Point( 
            4404126674439189967830289263441569083468351650968292179842762846697084622839,
            17079290243392766886859760889525175444965193217386659624290638225188885775992
        );                                      
        
        vk.IC[64] = Pairing.G1Point( 
            2450883016933609927726929913581303083958400743323551769503649061966232895276,
            5273232545259377186457261418099979521763545725927098318616051668885242456377
        );                                      
        
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[64] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
