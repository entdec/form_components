module FormComponents
  module TelephoneField
    # A phone number with its country's calling code, picked from a list of
    # countries with their flags (flag-icons, flags.css), sent
    # as "+31123456789".
    #
    # The number is typed without its code, in Rails' telephone_field with its
    # id and options but no name; a hidden field (Rails' hidden_field, with
    # its name) sends it with the code, kept up to date by the controller, so
    # like the color field it needs JS. A number without a code, as a plain
    # field sent it, is shown as it is, with the default country.
    class Component < FormComponents::Field::Component
      self.extras = superclass.extras + %i[country priority_countries corner_hint]

      # The country of a number without a code
      class_attribute :default_country, default: "nl"
      # The countries at the top of the list
      class_attribute :default_priority_countries, default: %w[nl de be fr gb]

      # Next to the label, above the field
      option_reader :corner_hint

      # Each country's calling code, by its ISO 3166 code
      CALLING_CODES = %w[
        ad:376 ae:971 af:93 ag:1 ai:1 al:355 am:374 ao:244 ar:54 as:1 at:43 au:61 aw:297 ax:358 az:994
        ba:387 bb:1 bd:880 be:32 bf:226 bg:359 bh:973 bi:257 bj:229 bl:590 bm:1 bn:673 bo:591 bq:599 br:55
        bs:1 bt:975 bw:267 by:375 bz:501 ca:1 cc:61 cd:243 cf:236 cg:242 ch:41 ci:225 ck:682 cl:56 cm:237
        cn:86 co:57 cr:506 cu:53 cv:238 cw:599 cx:61 cy:357 cz:420 de:49 dj:253 dk:45 dm:1 do:1 dz:213
        ec:593 ee:372 eg:20 eh:212 er:291 es:34 et:251 fi:358 fj:679 fk:500 fm:691 fo:298 fr:33 ga:241
        gb:44 gd:1 ge:995 gf:594 gg:44 gh:233 gi:350 gl:299 gm:220 gn:224 gp:590 gq:240 gr:30 gt:502 gu:1
        gw:245 gy:592 hk:852 hn:504 hr:385 ht:509 hu:36 id:62 ie:353 il:972 im:44 in:91 io:246 iq:964
        ir:98 is:354 it:39 je:44 jm:1 jo:962 jp:81 ke:254 kg:996 kh:855 ki:686 km:269 kn:1 kp:850 kr:82
        kw:965 ky:1 kz:7 la:856 lb:961 lc:1 li:423 lk:94 lr:231 ls:266 lt:370 lu:352 lv:371 ly:218 ma:212
        mc:377 md:373 me:382 mf:590 mg:261 mh:692 mk:389 ml:223 mm:95 mn:976 mo:853 mp:1 mq:596 mr:222
        ms:1 mt:356 mu:230 mv:960 mw:265 mx:52 my:60 mz:258 na:264 nc:687 ne:227 nf:672 ng:234 ni:505
        nl:31 no:47 np:977 nr:674 nu:683 nz:64 om:968 pa:507 pe:51 pf:689 pg:675 ph:63 pk:92 pl:48
        pm:508 pr:1 ps:970 pt:351 pw:680 py:595 qa:974 re:262 ro:40 rs:381 ru:7 rw:250 sa:966 sb:677
        sc:248 sd:249 se:46 sg:65 sh:290 si:386 sj:47 sk:421 sl:232 sm:378 sn:221 so:252 sr:597 ss:211
        st:239 sv:503 sx:1 sy:963 sz:268 tc:1 td:235 tg:228 th:66 tj:992 tk:690 tl:670 tm:993 tn:216
        to:676 tr:90 tt:1 tv:688 tw:886 tz:255 ua:380 ug:256 us:1 uy:598 uz:998 va:39 vc:1 ve:58 vg:1
        vi:1 vn:84 vu:678 wf:681 ws:685 xk:383 ye:967 yt:262 za:27 zm:260 zw:263
      ].to_h { |pair| pair.split(":") }.freeze

      # The country a code that several share means, unless it's the default
      # or a priority country's
      MAIN_COUNTRIES = {"1" => "us", "7" => "ru", "39" => "it", "44" => "gb", "47" => "no", "61" => "au", "212" => "ma",
                        "262" => "re", "290" => "sh", "358" => "fi", "590" => "gp", "599" => "cw"}.freeze

      def country
        code = options.fetch(:country, default_country).to_s.downcase
        CALLING_CODES.key?(code) ? code : default_country
      end

      def priority_countries
        Array(options.fetch(:priority_countries, default_priority_countries)).map { |code| code.to_s.downcase } & CALLING_CODES.keys
      end

      def value
        html_options.key?(:value) ? html_options[:value] : object&.public_send(method)
      end

      # The number's country and the number without its code, of "+31 6
      # 41085630" or "0031123456789"; without a code, the default country
      def parsed
        @parsed ||= begin
          number = value.to_s.strip.sub(/\A00/, "+")
          digits = number.delete("^0-9")
          code = (1..3).map { |length| digits[0, length] }.find { |prefix| CALLING_CODES.value?(prefix) } if number.start_with?("+")

          code ? [country_of(code), digits.delete_prefix(code)] : [country, number]
        end
      end

      def selected_country = parsed.first

      def national_number = parsed.last

      def calling_code = CALLING_CODES[selected_country]

      # Countries with the code, the main one of a shared code first, for the
      # controller to pick from as this does
      def countries
        main, others = CALLING_CODES.partition { |iso, code| MAIN_COUNTRIES.fetch(code, iso) == iso }
        main + others
      end

      def hidden_input
        rails(:hidden_field, method, html_options.slice(:index, :name, :form, :disabled).merge(id: nil, value: value, data: {"form-components--telephone-field-target": "value"}))
      end

      def input
        given = input_options(input_classes, from: html_options.except(:name, :value))
        rails(:telephone_field, method, given.merge(name: nil, value: national_number, autocomplete: given.fetch(:autocomplete, "tel-national"),
          data: (given[:data] || {}).merge("form-components--telephone-field-target": "number", action: "form-components--telephone-field#input")))
      end

      def wrapper_classes
        class_names("flex rounded-md bg-white outline outline-1 -outline-offset-1 focus-within:outline-2 focus-within:-outline-offset-1 auto-dark:bg-white/5",
          {"outline-gray-300 focus-within:outline-primary-600 auto-dark:outline-white/10" => !has_error?},
          {"outline-red-300 focus-within:outline-red-600 auto-dark:outline-red-500/50" => has_error?})
      end

      def input_classes
        class_names("block min-w-0 grow border-0 bg-transparent px-3 py-1.5 text-base placeholder:text-gray-400 focus:outline-none focus:ring-0 sm:text-sm/6 auto-dark:placeholder:text-gray-500",
          {"text-gray-900 auto-dark:text-white" => !has_error?},
          {"text-red-900 placeholder:text-red-300 auto-dark:text-red-300" => has_error?})
      end

      def country_label = I18n.t("form_components.telephone_field.country", default: "Country")

      def search_placeholder = I18n.t("form_components.telephone_field.search", default: "Search")

      private

      def country_of(code)
        ([country] + priority_countries + [MAIN_COUNTRIES[code]]).find { |iso| CALLING_CODES[iso] == code } ||
          CALLING_CODES.key(code)
      end
    end
  end
end
