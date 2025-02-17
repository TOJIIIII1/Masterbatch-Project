PGDMP  )    "    
            }         	   Inventory    16.2    16.2 �    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            �           1262    71234 	   Inventory    DATABASE     �   CREATE DATABASE "Inventory" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'English_United States.1252';
    DROP DATABASE "Inventory";
                postgres    false            �            1259    71239    material_codes    TABLE     �   CREATE TABLE public.material_codes (
    mid bigint NOT NULL,
    material_code character varying(255) NOT NULL,
    qty_per_packing double precision
);
 "   DROP TABLE public.material_codes;
       public         heap    postgres    false            �            1259    71238    material_codes_mid_seq    SEQUENCE        CREATE SEQUENCE public.material_codes_mid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.material_codes_mid_seq;
       public          postgres    false    216            �           0    0    material_codes_mid_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.material_codes_mid_seq OWNED BY public.material_codes.mid;
          public          postgres    false    215            �            1259    71548    notes    TABLE     �  CREATE TABLE public.notes (
    id integer NOT NULL,
    product_code character varying(255) NOT NULL,
    lot_number character varying(255) NOT NULL,
    product_kind character varying(255) DEFAULT 'MB'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    deleted boolean DEFAULT false NOT NULL,
    CONSTRAINT product_kind_check CHECK (((product_kind)::text = ANY ((ARRAY['MB'::character varying, 'DC'::character varying])::text[])))
);
    DROP TABLE public.notes;
       public         heap    postgres    false            �            1259    71547    notes_id_seq    SEQUENCE     �   CREATE SEQUENCE public.notes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 #   DROP SEQUENCE public.notes_id_seq;
       public          postgres    false    240            �           0    0    notes_id_seq    SEQUENCE OWNED BY     =   ALTER SEQUENCE public.notes_id_seq OWNED BY public.notes.id;
          public          postgres    false    239            �            1259    71291    wh1_outgoing_report    TABLE     U  CREATE TABLE public.wh1_outgoing_report (
    reference_no text NOT NULL,
    date_outgoing date NOT NULL,
    material_code integer NOT NULL,
    quantity double precision NOT NULL,
    area_location text NOT NULL,
    id bigint NOT NULL,
    deleted boolean DEFAULT false,
    status character varying DEFAULT 'Good'::character varying
);
 '   DROP TABLE public.wh1_outgoing_report;
       public         heap    postgres    false            �            1259    71306    wh1_preparation_form    TABLE     �  CREATE TABLE public.wh1_preparation_form (
    reference_no text NOT NULL,
    date date NOT NULL,
    material_code integer NOT NULL,
    quantity_prepared double precision NOT NULL,
    quantity_return double precision NOT NULL,
    area_location text NOT NULL,
    id bigint NOT NULL,
    deleted boolean DEFAULT false,
    status character varying DEFAULT 'Good'::character varying
);
 (   DROP TABLE public.wh1_preparation_form;
       public         heap    postgres    false            �            1259    71321    wh1_receiving_report    TABLE     I  CREATE TABLE public.wh1_receiving_report (
    reference_no text NOT NULL,
    date_received date NOT NULL,
    material_code integer NOT NULL,
    quantity double precision NOT NULL,
    area_location character varying NOT NULL,
    id bigint NOT NULL,
    deleted boolean DEFAULT false,
    status text DEFAULT 'Good'::text
);
 (   DROP TABLE public.wh1_receiving_report;
       public         heap    postgres    false            �            1259    71336    wh1_transfer_form    TABLE     "  CREATE TABLE public.wh1_transfer_form (
    reference_no text NOT NULL,
    date date NOT NULL,
    material_code integer,
    quantity double precision NOT NULL,
    area_to character varying,
    status character varying(100),
    id bigint NOT NULL,
    deleted boolean DEFAULT false
);
 %   DROP TABLE public.wh1_transfer_form;
       public         heap    postgres    false            �            1259    82421    wh1_material_code_totals    VIEW     ^  CREATE VIEW public.wh1_material_code_totals AS
 SELECT m.mid AS id,
    m.material_code AS material_code_name,
    sum(
        CASE
            WHEN ((r.status = (t.status)::text) OR (t.status IS NULL)) THEN COALESCE(r.total_received, (0.0)::double precision)
            ELSE (0.0)::double precision
        END) AS total_received_quantity,
    sum(COALESCE(o.total_outgoing, (0.0)::double precision)) AS total_outgoing_quantity,
    sum(
        CASE
            WHEN (r.status = (t.status)::text) THEN COALESCE(t.total_transferred, (0.0)::double precision)
            ELSE (0.0)::double precision
        END) AS total_transferred_quantity,
    sum(COALESCE(p.total_prepared, (0.0)::double precision)) AS total_prepared_quantity,
    sum(COALESCE(p.total_returned, (0.0)::double precision)) AS total_returned_quantity,
    sum(
        CASE
            WHEN ((r.status = (t.status)::text) OR (t.status IS NULL)) THEN ((((COALESCE(r.total_received, (0.0)::double precision) - COALESCE(o.total_outgoing, (0.0)::double precision)) - COALESCE(t.total_transferred, (0.0)::double precision)) - COALESCE(p.total_prepared, (0.0)::double precision)) + COALESCE(p.total_returned, (0.0)::double precision))
            ELSE (0.0)::double precision
        END) AS total_quantity,
    COALESCE(r.status, 'Good'::text) AS status
   FROM ((((public.material_codes m
     LEFT JOIN ( SELECT wh1_receiving_report.material_code,
            wh1_receiving_report.status,
            sum(wh1_receiving_report.quantity) AS total_received
           FROM public.wh1_receiving_report
          GROUP BY wh1_receiving_report.material_code, wh1_receiving_report.status) r ON ((m.mid = r.material_code)))
     LEFT JOIN ( SELECT wh1_outgoing_report.material_code,
            wh1_outgoing_report.status,
            sum(wh1_outgoing_report.quantity) AS total_outgoing
           FROM public.wh1_outgoing_report
          GROUP BY wh1_outgoing_report.material_code, wh1_outgoing_report.status) o ON (((m.mid = o.material_code) AND ((o.status)::text = r.status))))
     LEFT JOIN ( SELECT wh1_transfer_form.material_code,
            wh1_transfer_form.status,
            sum(wh1_transfer_form.quantity) AS total_transferred
           FROM public.wh1_transfer_form
          GROUP BY wh1_transfer_form.material_code, wh1_transfer_form.status) t ON (((m.mid = t.material_code) AND ((t.status)::text = r.status))))
     LEFT JOIN ( SELECT wh1_preparation_form.material_code,
            wh1_preparation_form.status,
            sum(wh1_preparation_form.quantity_prepared) AS total_prepared,
            sum(wh1_preparation_form.quantity_return) AS total_returned
           FROM public.wh1_preparation_form
          GROUP BY wh1_preparation_form.material_code, wh1_preparation_form.status) p ON (((m.mid = p.material_code) AND ((p.status)::text = r.status))))
  GROUP BY m.mid, m.material_code, r.status
  ORDER BY m.material_code;
 +   DROP VIEW public.wh1_material_code_totals;
       public          postgres    false    226    216    216    220    220    220    222    222    222    222    224    224    224    226    226            �            1259    71290    wh1_outgoing_report_id_seq    SEQUENCE     �   CREATE SEQUENCE public.wh1_outgoing_report_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.wh1_outgoing_report_id_seq;
       public          postgres    false    220            �           0    0    wh1_outgoing_report_id_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.wh1_outgoing_report_id_seq OWNED BY public.wh1_outgoing_report.id;
          public          postgres    false    219            �            1259    71305    wh1_preparation_form_id_seq    SEQUENCE     �   CREATE SEQUENCE public.wh1_preparation_form_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 2   DROP SEQUENCE public.wh1_preparation_form_id_seq;
       public          postgres    false    222            �           0    0    wh1_preparation_form_id_seq    SEQUENCE OWNED BY     [   ALTER SEQUENCE public.wh1_preparation_form_id_seq OWNED BY public.wh1_preparation_form.id;
          public          postgres    false    221            �            1259    71320    wh1_receiving_report_id_seq    SEQUENCE     �   CREATE SEQUENCE public.wh1_receiving_report_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 2   DROP SEQUENCE public.wh1_receiving_report_id_seq;
       public          postgres    false    224            �           0    0    wh1_receiving_report_id_seq    SEQUENCE OWNED BY     [   ALTER SEQUENCE public.wh1_receiving_report_id_seq OWNED BY public.wh1_receiving_report.id;
          public          postgres    false    223            �            1259    71272    wh1_spreadsheet    TABLE     @  CREATE TABLE public.wh1_spreadsheet (
    id bigint NOT NULL,
    material_code character varying(255) NOT NULL,
    no_of_bags double precision NOT NULL,
    qty_per_packing double precision NOT NULL,
    whse1_excess double precision NOT NULL,
    total double precision NOT NULL,
    status character varying(255)
);
 #   DROP TABLE public.wh1_spreadsheet;
       public         heap    postgres    false            �            1259    71271    wh1_spreadsheet_id_seq    SEQUENCE        CREATE SEQUENCE public.wh1_spreadsheet_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.wh1_spreadsheet_id_seq;
       public          postgres    false    218            �           0    0    wh1_spreadsheet_id_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.wh1_spreadsheet_id_seq OWNED BY public.wh1_spreadsheet.id;
          public          postgres    false    217            �            1259    71335    wh1_transfer_form_id_seq    SEQUENCE     �   CREATE SEQUENCE public.wh1_transfer_form_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.wh1_transfer_form_id_seq;
       public          postgres    false    226            �           0    0    wh1_transfer_form_id_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.wh1_transfer_form_id_seq OWNED BY public.wh1_transfer_form.id;
          public          postgres    false    225            �            1259    71557    wh2_material_codes_mid_seq    SEQUENCE     �   CREATE SEQUENCE public.wh2_material_codes_mid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.wh2_material_codes_mid_seq;
       public          postgres    false            �            1259    71362    wh2_material_codes    TABLE       CREATE TABLE public.wh2_material_codes (
    mid bigint DEFAULT nextval('public.wh2_material_codes_mid_seq'::regclass) NOT NULL,
    material_code character varying(255) NOT NULL,
    qty_per_packing double precision,
    area_location character varying(255)
);
 &   DROP TABLE public.wh2_material_codes;
       public         heap    postgres    false    241            �            1259    71380    wh2_outgoing_report    TABLE     U  CREATE TABLE public.wh2_outgoing_report (
    reference_no text NOT NULL,
    date_outgoing date NOT NULL,
    material_code integer NOT NULL,
    quantity double precision NOT NULL,
    area_location text NOT NULL,
    id bigint NOT NULL,
    deleted boolean DEFAULT false,
    status character varying DEFAULT 'Good'::character varying
);
 '   DROP TABLE public.wh2_outgoing_report;
       public         heap    postgres    false            �            1259    71406    wh2_preparation_form    TABLE     �  CREATE TABLE public.wh2_preparation_form (
    reference_no text NOT NULL,
    date date NOT NULL,
    material_code integer NOT NULL,
    quantity_prepared double precision NOT NULL,
    quantity_return double precision NOT NULL,
    area_location text NOT NULL,
    id bigint DEFAULT nextval('public.wh1_preparation_form_id_seq'::regclass) NOT NULL,
    deleted boolean DEFAULT false,
    status character varying DEFAULT 'Good'::character varying
);
 (   DROP TABLE public.wh2_preparation_form;
       public         heap    postgres    false    221            �            1259    71435    wh2_receiving_report    TABLE     �  CREATE TABLE public.wh2_receiving_report (
    reference_no text NOT NULL,
    date_received date NOT NULL,
    material_code integer NOT NULL,
    quantity double precision NOT NULL,
    area_location character varying NOT NULL,
    id bigint DEFAULT nextval('public.wh1_receiving_report_id_seq'::regclass) NOT NULL,
    deleted boolean DEFAULT false,
    status text DEFAULT 'Good'::text
);
 (   DROP TABLE public.wh2_receiving_report;
       public         heap    postgres    false    223            �            1259    71562    wh2_transfer_form_id_seq    SEQUENCE     �   CREATE SEQUENCE public.wh2_transfer_form_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.wh2_transfer_form_id_seq;
       public          postgres    false            �            1259    71516    wh2_transfer_form    TABLE     _  CREATE TABLE public.wh2_transfer_form (
    reference_no text NOT NULL,
    date date NOT NULL,
    material_code integer,
    quantity double precision NOT NULL,
    area_to character varying,
    status character varying(100),
    id bigint DEFAULT nextval('public.wh2_transfer_form_id_seq'::regclass) NOT NULL,
    deleted boolean DEFAULT false
);
 %   DROP TABLE public.wh2_transfer_form;
       public         heap    postgres    false    244            �            1259    82416    wh2_material_code_totals    VIEW     b  CREATE VIEW public.wh2_material_code_totals AS
 SELECT m.mid AS id,
    m.material_code AS material_code_name,
    sum(
        CASE
            WHEN ((r.status = (t.status)::text) OR (t.status IS NULL)) THEN COALESCE(r.total_received, (0.0)::double precision)
            ELSE (0.0)::double precision
        END) AS total_received_quantity,
    sum(COALESCE(o.total_outgoing, (0.0)::double precision)) AS total_outgoing_quantity,
    sum(
        CASE
            WHEN (r.status = (t.status)::text) THEN COALESCE(t.total_transferred, (0.0)::double precision)
            ELSE (0.0)::double precision
        END) AS total_transferred_quantity,
    sum(COALESCE(p.total_prepared, (0.0)::double precision)) AS total_prepared_quantity,
    sum(COALESCE(p.total_returned, (0.0)::double precision)) AS total_returned_quantity,
    sum(
        CASE
            WHEN ((r.status = (t.status)::text) OR (t.status IS NULL)) THEN ((((COALESCE(r.total_received, (0.0)::double precision) - COALESCE(o.total_outgoing, (0.0)::double precision)) - COALESCE(t.total_transferred, (0.0)::double precision)) - COALESCE(p.total_prepared, (0.0)::double precision)) + COALESCE(p.total_returned, (0.0)::double precision))
            ELSE (0.0)::double precision
        END) AS total_quantity,
    COALESCE(r.status, 'Good'::text) AS status
   FROM ((((public.wh2_material_codes m
     LEFT JOIN ( SELECT wh2_receiving_report.material_code,
            wh2_receiving_report.status,
            sum(wh2_receiving_report.quantity) AS total_received
           FROM public.wh2_receiving_report
          GROUP BY wh2_receiving_report.material_code, wh2_receiving_report.status) r ON ((m.mid = r.material_code)))
     LEFT JOIN ( SELECT wh2_outgoing_report.material_code,
            wh2_outgoing_report.status,
            sum(wh2_outgoing_report.quantity) AS total_outgoing
           FROM public.wh2_outgoing_report
          GROUP BY wh2_outgoing_report.material_code, wh2_outgoing_report.status) o ON (((m.mid = o.material_code) AND ((o.status)::text = r.status))))
     LEFT JOIN ( SELECT wh2_transfer_form.material_code,
            wh2_transfer_form.status,
            sum(wh2_transfer_form.quantity) AS total_transferred
           FROM public.wh2_transfer_form
          GROUP BY wh2_transfer_form.material_code, wh2_transfer_form.status) t ON (((m.mid = t.material_code) AND ((t.status)::text = r.status))))
     LEFT JOIN ( SELECT wh2_preparation_form.material_code,
            wh2_preparation_form.status,
            sum(wh2_preparation_form.quantity_prepared) AS total_prepared,
            sum(wh2_preparation_form.quantity_return) AS total_returned
           FROM public.wh2_preparation_form
          GROUP BY wh2_preparation_form.material_code, wh2_preparation_form.status) p ON (((m.mid = p.material_code) AND ((p.status)::text = r.status))))
  GROUP BY m.mid, m.material_code, r.status
  ORDER BY m.material_code;
 +   DROP VIEW public.wh2_material_code_totals;
       public          postgres    false    227    227    229    229    238    238    238    233    233    231    233    229    231    231    231            �            1259    83692    wh2_outgoing_report_id_seq    SEQUENCE     �   CREATE SEQUENCE public.wh2_outgoing_report_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.wh2_outgoing_report_id_seq;
       public          postgres    false    229            �           0    0    wh2_outgoing_report_id_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.wh2_outgoing_report_id_seq OWNED BY public.wh2_outgoing_report.id;
          public          postgres    false    252            �            1259    71560    wh2_spreadsheet_id_seq    SEQUENCE        CREATE SEQUENCE public.wh2_spreadsheet_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.wh2_spreadsheet_id_seq;
       public          postgres    false            �            1259    71466    wh2_spreadsheet    TABLE     {  CREATE TABLE public.wh2_spreadsheet (
    id bigint DEFAULT nextval('public.wh2_spreadsheet_id_seq'::regclass) NOT NULL,
    material_code character varying(255) NOT NULL,
    no_of_bags double precision NOT NULL,
    qty_per_packing double precision NOT NULL,
    whse1_excess double precision NOT NULL,
    total double precision NOT NULL,
    status character varying(255)
);
 #   DROP TABLE public.wh2_spreadsheet;
       public         heap    postgres    false    243            �            1259    71559    wh2_spreadsheet_mid_seq    SEQUENCE     �   CREATE SEQUENCE public.wh2_spreadsheet_mid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.wh2_spreadsheet_mid_seq;
       public          postgres    false            �            1259    71371    wh4_material_codes    TABLE     �   CREATE TABLE public.wh4_material_codes (
    mid bigint NOT NULL,
    material_code character varying(255) NOT NULL,
    qty_per_packing double precision,
    area_location character varying(255)
);
 &   DROP TABLE public.wh4_material_codes;
       public         heap    postgres    false            �            1259    71393    wh4_outgoing_report    TABLE     U  CREATE TABLE public.wh4_outgoing_report (
    reference_no text NOT NULL,
    date_outgoing date NOT NULL,
    material_code integer NOT NULL,
    quantity double precision NOT NULL,
    area_location text NOT NULL,
    id bigint NOT NULL,
    deleted boolean DEFAULT false,
    status character varying DEFAULT 'Good'::character varying
);
 '   DROP TABLE public.wh4_outgoing_report;
       public         heap    postgres    false            �            1259    71420    wh4_preparation_form    TABLE     �  CREATE TABLE public.wh4_preparation_form (
    reference_no text NOT NULL,
    date date NOT NULL,
    material_code integer NOT NULL,
    quantity_prepared double precision NOT NULL,
    quantity_return double precision NOT NULL,
    area_location text NOT NULL,
    id bigint DEFAULT nextval('public.wh1_preparation_form_id_seq'::regclass) NOT NULL,
    deleted boolean DEFAULT false,
    status character varying DEFAULT 'Good'::character varying
);
 (   DROP TABLE public.wh4_preparation_form;
       public         heap    postgres    false    221            �            1259    71449    wh4_receiving_report    TABLE     t  CREATE TABLE public.wh4_receiving_report (
    reference_no text NOT NULL,
    date_received date NOT NULL,
    material_code integer NOT NULL,
    quantity double precision NOT NULL,
    area_location character varying NOT NULL,
    id bigint DEFAULT nextval('public.wh1_receiving_report_id_seq'::regclass) NOT NULL,
    deleted boolean DEFAULT false,
    status text
);
 (   DROP TABLE public.wh4_receiving_report;
       public         heap    postgres    false    223            �            1259    81661    wh4_transfer_form_id_seq    SEQUENCE     �   CREATE SEQUENCE public.wh4_transfer_form_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.wh4_transfer_form_id_seq;
       public          postgres    false            �            1259    71503    wh4_transfer_form    TABLE     �  CREATE TABLE public.wh4_transfer_form (
    reference_no text NOT NULL,
    date date NOT NULL,
    material_code integer,
    quantity double precision NOT NULL,
    area_to character varying,
    status character varying(100),
    id bigint DEFAULT nextval('public.wh4_transfer_form_id_seq'::regclass) NOT NULL,
    deleted boolean DEFAULT false,
    new_status character varying DEFAULT 'Good'::character varying
);
 %   DROP TABLE public.wh4_transfer_form;
       public         heap    postgres    false    247            �            1259    82411    wh4_material_code_totals    VIEW     b  CREATE VIEW public.wh4_material_code_totals AS
 SELECT m.mid AS id,
    m.material_code AS material_code_name,
    sum(
        CASE
            WHEN ((r.status = (t.status)::text) OR (t.status IS NULL)) THEN COALESCE(r.total_received, (0.0)::double precision)
            ELSE (0.0)::double precision
        END) AS total_received_quantity,
    sum(COALESCE(o.total_outgoing, (0.0)::double precision)) AS total_outgoing_quantity,
    sum(
        CASE
            WHEN (r.status = (t.status)::text) THEN COALESCE(t.total_transferred, (0.0)::double precision)
            ELSE (0.0)::double precision
        END) AS total_transferred_quantity,
    sum(COALESCE(p.total_prepared, (0.0)::double precision)) AS total_prepared_quantity,
    sum(COALESCE(p.total_returned, (0.0)::double precision)) AS total_returned_quantity,
    sum(
        CASE
            WHEN ((r.status = (t.status)::text) OR (t.status IS NULL)) THEN ((((COALESCE(r.total_received, (0.0)::double precision) - COALESCE(o.total_outgoing, (0.0)::double precision)) - COALESCE(t.total_transferred, (0.0)::double precision)) - COALESCE(p.total_prepared, (0.0)::double precision)) + COALESCE(p.total_returned, (0.0)::double precision))
            ELSE (0.0)::double precision
        END) AS total_quantity,
    COALESCE(r.status, 'Good'::text) AS status
   FROM ((((public.wh4_material_codes m
     LEFT JOIN ( SELECT wh4_receiving_report.material_code,
            wh4_receiving_report.status,
            sum(wh4_receiving_report.quantity) AS total_received
           FROM public.wh4_receiving_report
          GROUP BY wh4_receiving_report.material_code, wh4_receiving_report.status) r ON ((m.mid = r.material_code)))
     LEFT JOIN ( SELECT wh4_outgoing_report.material_code,
            wh4_outgoing_report.status,
            sum(wh4_outgoing_report.quantity) AS total_outgoing
           FROM public.wh4_outgoing_report
          GROUP BY wh4_outgoing_report.material_code, wh4_outgoing_report.status) o ON (((m.mid = o.material_code) AND ((o.status)::text = r.status))))
     LEFT JOIN ( SELECT wh4_transfer_form.material_code,
            wh4_transfer_form.status,
            sum(wh4_transfer_form.quantity) AS total_transferred
           FROM public.wh4_transfer_form
          GROUP BY wh4_transfer_form.material_code, wh4_transfer_form.status) t ON (((m.mid = t.material_code) AND ((t.status)::text = r.status))))
     LEFT JOIN ( SELECT wh4_preparation_form.material_code,
            wh4_preparation_form.status,
            sum(wh4_preparation_form.quantity_prepared) AS total_prepared,
            sum(wh4_preparation_form.quantity_return) AS total_returned
           FROM public.wh4_preparation_form
          GROUP BY wh4_preparation_form.material_code, wh4_preparation_form.status) p ON (((m.mid = p.material_code) AND ((p.status)::text = r.status))))
  GROUP BY m.mid, m.material_code, r.status
  ORDER BY m.material_code;
 +   DROP VIEW public.wh4_material_code_totals;
       public          postgres    false    234    237    237    237    228    228    230    230    230    232    232    232    232    234    234            �            1259    71564    wh4_material_codes_mid_seq    SEQUENCE     �   CREATE SEQUENCE public.wh4_material_codes_mid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.wh4_material_codes_mid_seq;
       public          postgres    false    228            �           0    0    wh4_material_codes_mid_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.wh4_material_codes_mid_seq OWNED BY public.wh4_material_codes.mid;
          public          postgres    false    245            �            1259    83694    wh4_outgoing_report_id_seq    SEQUENCE     �   CREATE SEQUENCE public.wh4_outgoing_report_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.wh4_outgoing_report_id_seq;
       public          postgres    false    230            �           0    0    wh4_outgoing_report_id_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.wh4_outgoing_report_id_seq OWNED BY public.wh4_outgoing_report.id;
          public          postgres    false    253            �            1259    71786    wh4_spreadsheet_id_seq    SEQUENCE        CREATE SEQUENCE public.wh4_spreadsheet_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.wh4_spreadsheet_id_seq;
       public          postgres    false            �            1259    71483    wh4_spreadsheet    TABLE     {  CREATE TABLE public.wh4_spreadsheet (
    id bigint DEFAULT nextval('public.wh4_spreadsheet_id_seq'::regclass) NOT NULL,
    material_code character varying(255) NOT NULL,
    no_of_bags double precision NOT NULL,
    qty_per_packing double precision NOT NULL,
    whse1_excess double precision NOT NULL,
    total double precision NOT NULL,
    status character varying(255)
);
 #   DROP TABLE public.wh4_spreadsheet;
       public         heap    postgres    false    246            �            1259    81664    wh4_transfer_from_id_seq    SEQUENCE     �   CREATE SEQUENCE public.wh4_transfer_from_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.wh4_transfer_from_id_seq;
       public          postgres    false            `           2604    71242    material_codes mid    DEFAULT     x   ALTER TABLE ONLY public.material_codes ALTER COLUMN mid SET DEFAULT nextval('public.material_codes_mid_seq'::regclass);
 A   ALTER TABLE public.material_codes ALTER COLUMN mid DROP DEFAULT;
       public          postgres    false    216    215    216            �           2604    71551    notes id    DEFAULT     d   ALTER TABLE ONLY public.notes ALTER COLUMN id SET DEFAULT nextval('public.notes_id_seq'::regclass);
 7   ALTER TABLE public.notes ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    239    240    240            b           2604    71294    wh1_outgoing_report id    DEFAULT     �   ALTER TABLE ONLY public.wh1_outgoing_report ALTER COLUMN id SET DEFAULT nextval('public.wh1_outgoing_report_id_seq'::regclass);
 E   ALTER TABLE public.wh1_outgoing_report ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    220    219    220            e           2604    71309    wh1_preparation_form id    DEFAULT     �   ALTER TABLE ONLY public.wh1_preparation_form ALTER COLUMN id SET DEFAULT nextval('public.wh1_preparation_form_id_seq'::regclass);
 F   ALTER TABLE public.wh1_preparation_form ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    221    222    222            h           2604    71324    wh1_receiving_report id    DEFAULT     �   ALTER TABLE ONLY public.wh1_receiving_report ALTER COLUMN id SET DEFAULT nextval('public.wh1_receiving_report_id_seq'::regclass);
 F   ALTER TABLE public.wh1_receiving_report ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    224    223    224            a           2604    71275    wh1_spreadsheet id    DEFAULT     x   ALTER TABLE ONLY public.wh1_spreadsheet ALTER COLUMN id SET DEFAULT nextval('public.wh1_spreadsheet_id_seq'::regclass);
 A   ALTER TABLE public.wh1_spreadsheet ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    218    217    218            k           2604    71339    wh1_transfer_form id    DEFAULT     |   ALTER TABLE ONLY public.wh1_transfer_form ALTER COLUMN id SET DEFAULT nextval('public.wh1_transfer_form_id_seq'::regclass);
 C   ALTER TABLE public.wh1_transfer_form ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    226    225    226            o           2604    83695    wh2_outgoing_report id    DEFAULT     �   ALTER TABLE ONLY public.wh2_outgoing_report ALTER COLUMN id SET DEFAULT nextval('public.wh2_outgoing_report_id_seq'::regclass);
 E   ALTER TABLE public.wh2_outgoing_report ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    252    229            n           2604    71565    wh4_material_codes mid    DEFAULT     �   ALTER TABLE ONLY public.wh4_material_codes ALTER COLUMN mid SET DEFAULT nextval('public.wh4_material_codes_mid_seq'::regclass);
 E   ALTER TABLE public.wh4_material_codes ALTER COLUMN mid DROP DEFAULT;
       public          postgres    false    245    228            r           2604    83696    wh4_outgoing_report id    DEFAULT     �   ALTER TABLE ONLY public.wh4_outgoing_report ALTER COLUMN id SET DEFAULT nextval('public.wh4_outgoing_report_id_seq'::regclass);
 E   ALTER TABLE public.wh4_outgoing_report ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    253    230            ^          0    71239    material_codes 
   TABLE DATA           M   COPY public.material_codes (mid, material_code, qty_per_packing) FROM stdin;
    public          postgres    false    216   x�       v          0    71548    notes 
   TABLE DATA           `   COPY public.notes (id, product_code, lot_number, product_kind, created_at, deleted) FROM stdin;
    public          postgres    false    240   ��       b          0    71291    wh1_outgoing_report 
   TABLE DATA           �   COPY public.wh1_outgoing_report (reference_no, date_outgoing, material_code, quantity, area_location, id, deleted, status) FROM stdin;
    public          postgres    false    220   ��       d          0    71306    wh1_preparation_form 
   TABLE DATA           �   COPY public.wh1_preparation_form (reference_no, date, material_code, quantity_prepared, quantity_return, area_location, id, deleted, status) FROM stdin;
    public          postgres    false    222   ��       f          0    71321    wh1_receiving_report 
   TABLE DATA           �   COPY public.wh1_receiving_report (reference_no, date_received, material_code, quantity, area_location, id, deleted, status) FROM stdin;
    public          postgres    false    224   ��       `          0    71272    wh1_spreadsheet 
   TABLE DATA           v   COPY public.wh1_spreadsheet (id, material_code, no_of_bags, qty_per_packing, whse1_excess, total, status) FROM stdin;
    public          postgres    false    218   	�       h          0    71336    wh1_transfer_form 
   TABLE DATA           v   COPY public.wh1_transfer_form (reference_no, date, material_code, quantity, area_to, status, id, deleted) FROM stdin;
    public          postgres    false    226   &�       i          0    71362    wh2_material_codes 
   TABLE DATA           `   COPY public.wh2_material_codes (mid, material_code, qty_per_packing, area_location) FROM stdin;
    public          postgres    false    227   C�       k          0    71380    wh2_outgoing_report 
   TABLE DATA           �   COPY public.wh2_outgoing_report (reference_no, date_outgoing, material_code, quantity, area_location, id, deleted, status) FROM stdin;
    public          postgres    false    229   `�       m          0    71406    wh2_preparation_form 
   TABLE DATA           �   COPY public.wh2_preparation_form (reference_no, date, material_code, quantity_prepared, quantity_return, area_location, id, deleted, status) FROM stdin;
    public          postgres    false    231   }�       o          0    71435    wh2_receiving_report 
   TABLE DATA           �   COPY public.wh2_receiving_report (reference_no, date_received, material_code, quantity, area_location, id, deleted, status) FROM stdin;
    public          postgres    false    233   ��       q          0    71466    wh2_spreadsheet 
   TABLE DATA           v   COPY public.wh2_spreadsheet (id, material_code, no_of_bags, qty_per_packing, whse1_excess, total, status) FROM stdin;
    public          postgres    false    235   ��       t          0    71516    wh2_transfer_form 
   TABLE DATA           v   COPY public.wh2_transfer_form (reference_no, date, material_code, quantity, area_to, status, id, deleted) FROM stdin;
    public          postgres    false    238   ��       j          0    71371    wh4_material_codes 
   TABLE DATA           `   COPY public.wh4_material_codes (mid, material_code, qty_per_packing, area_location) FROM stdin;
    public          postgres    false    228   ��       l          0    71393    wh4_outgoing_report 
   TABLE DATA           �   COPY public.wh4_outgoing_report (reference_no, date_outgoing, material_code, quantity, area_location, id, deleted, status) FROM stdin;
    public          postgres    false    230   �       n          0    71420    wh4_preparation_form 
   TABLE DATA           �   COPY public.wh4_preparation_form (reference_no, date, material_code, quantity_prepared, quantity_return, area_location, id, deleted, status) FROM stdin;
    public          postgres    false    232   +�       p          0    71449    wh4_receiving_report 
   TABLE DATA           �   COPY public.wh4_receiving_report (reference_no, date_received, material_code, quantity, area_location, id, deleted, status) FROM stdin;
    public          postgres    false    234   H�       r          0    71483    wh4_spreadsheet 
   TABLE DATA           v   COPY public.wh4_spreadsheet (id, material_code, no_of_bags, qty_per_packing, whse1_excess, total, status) FROM stdin;
    public          postgres    false    236   e�       s          0    71503    wh4_transfer_form 
   TABLE DATA           �   COPY public.wh4_transfer_form (reference_no, date, material_code, quantity, area_to, status, id, deleted, new_status) FROM stdin;
    public          postgres    false    237   ��       �           0    0    material_codes_mid_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.material_codes_mid_seq', 290, true);
          public          postgres    false    215            �           0    0    notes_id_seq    SEQUENCE SET     ;   SELECT pg_catalog.setval('public.notes_id_seq', 19, true);
          public          postgres    false    239            �           0    0    wh1_outgoing_report_id_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('public.wh1_outgoing_report_id_seq', 62, true);
          public          postgres    false    219            �           0    0    wh1_preparation_form_id_seq    SEQUENCE SET     K   SELECT pg_catalog.setval('public.wh1_preparation_form_id_seq', 244, true);
          public          postgres    false    221            �           0    0    wh1_receiving_report_id_seq    SEQUENCE SET     K   SELECT pg_catalog.setval('public.wh1_receiving_report_id_seq', 305, true);
          public          postgres    false    223            �           0    0    wh1_spreadsheet_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.wh1_spreadsheet_id_seq', 3837, true);
          public          postgres    false    217            �           0    0    wh1_transfer_form_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.wh1_transfer_form_id_seq', 94, true);
          public          postgres    false    225            �           0    0    wh2_material_codes_mid_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('public.wh2_material_codes_mid_seq', 278, true);
          public          postgres    false    241            �           0    0    wh2_outgoing_report_id_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.wh2_outgoing_report_id_seq', 3, true);
          public          postgres    false    252            �           0    0    wh2_spreadsheet_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.wh2_spreadsheet_id_seq', 1511, true);
          public          postgres    false    243            �           0    0    wh2_spreadsheet_mid_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.wh2_spreadsheet_mid_seq', 1, false);
          public          postgres    false    242            �           0    0    wh2_transfer_form_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.wh2_transfer_form_id_seq', 41, true);
          public          postgres    false    244            �           0    0    wh4_material_codes_mid_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('public.wh4_material_codes_mid_seq', 1, false);
          public          postgres    false    245            �           0    0    wh4_outgoing_report_id_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.wh4_outgoing_report_id_seq', 4, true);
          public          postgres    false    253            �           0    0    wh4_spreadsheet_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.wh4_spreadsheet_id_seq', 1852, true);
          public          postgres    false    246            �           0    0    wh4_transfer_form_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.wh4_transfer_form_id_seq', 36, true);
          public          postgres    false    247            �           0    0    wh4_transfer_from_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.wh4_transfer_from_id_seq', 1, false);
          public          postgres    false    248            �           2606    71368 &   wh2_material_codes material_codes_2key 
   CONSTRAINT     e   ALTER TABLE ONLY public.wh2_material_codes
    ADD CONSTRAINT material_codes_2key PRIMARY KEY (mid);
 P   ALTER TABLE ONLY public.wh2_material_codes DROP CONSTRAINT material_codes_2key;
       public            postgres    false    227            �           2606    71377 &   wh4_material_codes material_codes_4key 
   CONSTRAINT     e   ALTER TABLE ONLY public.wh4_material_codes
    ADD CONSTRAINT material_codes_4key PRIMARY KEY (mid);
 P   ALTER TABLE ONLY public.wh4_material_codes DROP CONSTRAINT material_codes_4key;
       public            postgres    false    228            �           2606    71246 "   material_codes material_codes_pkey 
   CONSTRAINT     a   ALTER TABLE ONLY public.material_codes
    ADD CONSTRAINT material_codes_pkey PRIMARY KEY (mid);
 L   ALTER TABLE ONLY public.material_codes DROP CONSTRAINT material_codes_pkey;
       public            postgres    false    216            �           2606    71556    notes notes_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_pkey PRIMARY KEY (id);
 :   ALTER TABLE ONLY public.notes DROP CONSTRAINT notes_pkey;
       public            postgres    false    240            �           2606    80208 #   material_codes unique_material_code 
   CONSTRAINT     g   ALTER TABLE ONLY public.material_codes
    ADD CONSTRAINT unique_material_code UNIQUE (material_code);
 M   ALTER TABLE ONLY public.material_codes DROP CONSTRAINT unique_material_code;
       public            postgres    false    216            �           2606    71370 (   wh2_material_codes unique_material_code2 
   CONSTRAINT     l   ALTER TABLE ONLY public.wh2_material_codes
    ADD CONSTRAINT unique_material_code2 UNIQUE (material_code);
 R   ALTER TABLE ONLY public.wh2_material_codes DROP CONSTRAINT unique_material_code2;
       public            postgres    false    227            �           2606    71379 (   wh4_material_codes unique_material_code4 
   CONSTRAINT     l   ALTER TABLE ONLY public.wh4_material_codes
    ADD CONSTRAINT unique_material_code4 UNIQUE (material_code);
 R   ALTER TABLE ONLY public.wh4_material_codes DROP CONSTRAINT unique_material_code4;
       public            postgres    false    228            �           2606    71299 ,   wh1_outgoing_report wh1_outgoing_report_pkey 
   CONSTRAINT     j   ALTER TABLE ONLY public.wh1_outgoing_report
    ADD CONSTRAINT wh1_outgoing_report_pkey PRIMARY KEY (id);
 V   ALTER TABLE ONLY public.wh1_outgoing_report DROP CONSTRAINT wh1_outgoing_report_pkey;
       public            postgres    false    220            �           2606    71314 .   wh1_preparation_form wh1_preparation_form_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY public.wh1_preparation_form
    ADD CONSTRAINT wh1_preparation_form_pkey PRIMARY KEY (id);
 X   ALTER TABLE ONLY public.wh1_preparation_form DROP CONSTRAINT wh1_preparation_form_pkey;
       public            postgres    false    222            �           2606    71329 .   wh1_receiving_report wh1_receiving_report_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY public.wh1_receiving_report
    ADD CONSTRAINT wh1_receiving_report_pkey PRIMARY KEY (id);
 X   ALTER TABLE ONLY public.wh1_receiving_report DROP CONSTRAINT wh1_receiving_report_pkey;
       public            postgres    false    224            �           2606    71279 $   wh1_spreadsheet wh1_spreedsheet_1key 
   CONSTRAINT     b   ALTER TABLE ONLY public.wh1_spreadsheet
    ADD CONSTRAINT wh1_spreedsheet_1key PRIMARY KEY (id);
 N   ALTER TABLE ONLY public.wh1_spreadsheet DROP CONSTRAINT wh1_spreedsheet_1key;
       public            postgres    false    218            �           2606    71344 (   wh1_transfer_form wh1_transfer_form_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.wh1_transfer_form
    ADD CONSTRAINT wh1_transfer_form_pkey PRIMARY KEY (id);
 R   ALTER TABLE ONLY public.wh1_transfer_form DROP CONSTRAINT wh1_transfer_form_pkey;
       public            postgres    false    226            �           2606    71387 ,   wh2_outgoing_report wh2_outgoing_report_pkey 
   CONSTRAINT     j   ALTER TABLE ONLY public.wh2_outgoing_report
    ADD CONSTRAINT wh2_outgoing_report_pkey PRIMARY KEY (id);
 V   ALTER TABLE ONLY public.wh2_outgoing_report DROP CONSTRAINT wh2_outgoing_report_pkey;
       public            postgres    false    229            �           2606    71414 .   wh2_preparation_form wh2_preparation_form_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY public.wh2_preparation_form
    ADD CONSTRAINT wh2_preparation_form_pkey PRIMARY KEY (id);
 X   ALTER TABLE ONLY public.wh2_preparation_form DROP CONSTRAINT wh2_preparation_form_pkey;
       public            postgres    false    231            �           2606    71443 .   wh2_receiving_report wh2_receiving_report_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY public.wh2_receiving_report
    ADD CONSTRAINT wh2_receiving_report_pkey PRIMARY KEY (id);
 X   ALTER TABLE ONLY public.wh2_receiving_report DROP CONSTRAINT wh2_receiving_report_pkey;
       public            postgres    false    233            �           2606    71472 $   wh2_spreadsheet wh2_spreedsheet_1key 
   CONSTRAINT     b   ALTER TABLE ONLY public.wh2_spreadsheet
    ADD CONSTRAINT wh2_spreedsheet_1key PRIMARY KEY (id);
 N   ALTER TABLE ONLY public.wh2_spreadsheet DROP CONSTRAINT wh2_spreedsheet_1key;
       public            postgres    false    235            �           2606    71523 (   wh2_transfer_form wh2_transfer_form_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.wh2_transfer_form
    ADD CONSTRAINT wh2_transfer_form_pkey PRIMARY KEY (id);
 R   ALTER TABLE ONLY public.wh2_transfer_form DROP CONSTRAINT wh2_transfer_form_pkey;
       public            postgres    false    238            �           2606    71400 ,   wh4_outgoing_report wh4_outgoing_report_pkey 
   CONSTRAINT     j   ALTER TABLE ONLY public.wh4_outgoing_report
    ADD CONSTRAINT wh4_outgoing_report_pkey PRIMARY KEY (id);
 V   ALTER TABLE ONLY public.wh4_outgoing_report DROP CONSTRAINT wh4_outgoing_report_pkey;
       public            postgres    false    230            �           2606    71428 .   wh4_preparation_form wh4_preparation_form_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY public.wh4_preparation_form
    ADD CONSTRAINT wh4_preparation_form_pkey PRIMARY KEY (id);
 X   ALTER TABLE ONLY public.wh4_preparation_form DROP CONSTRAINT wh4_preparation_form_pkey;
       public            postgres    false    232            �           2606    71457 .   wh4_receiving_report wh4_receiving_report_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY public.wh4_receiving_report
    ADD CONSTRAINT wh4_receiving_report_pkey PRIMARY KEY (id);
 X   ALTER TABLE ONLY public.wh4_receiving_report DROP CONSTRAINT wh4_receiving_report_pkey;
       public            postgres    false    234            �           2606    71489 $   wh4_spreadsheet wh4_spreedsheet_1key 
   CONSTRAINT     b   ALTER TABLE ONLY public.wh4_spreadsheet
    ADD CONSTRAINT wh4_spreedsheet_1key PRIMARY KEY (id);
 N   ALTER TABLE ONLY public.wh4_spreadsheet DROP CONSTRAINT wh4_spreedsheet_1key;
       public            postgres    false    236            �           2606    81663 (   wh4_transfer_form wh4_transfer_form_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.wh4_transfer_form
    ADD CONSTRAINT wh4_transfer_form_pkey PRIMARY KEY (id);
 R   ALTER TABLE ONLY public.wh4_transfer_form DROP CONSTRAINT wh4_transfer_form_pkey;
       public            postgres    false    237            �           1259    80203    unique_material_code_idx    INDEX     �   CREATE UNIQUE INDEX unique_material_code_idx ON public.material_codes USING btree (material_code) WHERE (material_code IS NOT NULL);
 ,   DROP INDEX public.unique_material_code_idx;
       public            postgres    false    216    216            �           2606    71315 %   wh1_preparation_form fk_material_code    FK CONSTRAINT     �   ALTER TABLE ONLY public.wh1_preparation_form
    ADD CONSTRAINT fk_material_code FOREIGN KEY (material_code) REFERENCES public.material_codes(mid);
 O   ALTER TABLE ONLY public.wh1_preparation_form DROP CONSTRAINT fk_material_code;
       public          postgres    false    216    4749    222            �           2606    71330 %   wh1_receiving_report fk_material_code    FK CONSTRAINT     �   ALTER TABLE ONLY public.wh1_receiving_report
    ADD CONSTRAINT fk_material_code FOREIGN KEY (material_code) REFERENCES public.material_codes(mid);
 O   ALTER TABLE ONLY public.wh1_receiving_report DROP CONSTRAINT fk_material_code;
       public          postgres    false    4749    216    224            �           2606    71345 "   wh1_transfer_form fk_material_code    FK CONSTRAINT     �   ALTER TABLE ONLY public.wh1_transfer_form
    ADD CONSTRAINT fk_material_code FOREIGN KEY (material_code) REFERENCES public.material_codes(mid);
 L   ALTER TABLE ONLY public.wh1_transfer_form DROP CONSTRAINT fk_material_code;
       public          postgres    false    4749    226    216            �           2606    71415 %   wh2_preparation_form fk_material_code    FK CONSTRAINT     �   ALTER TABLE ONLY public.wh2_preparation_form
    ADD CONSTRAINT fk_material_code FOREIGN KEY (material_code) REFERENCES public.wh2_material_codes(mid);
 O   ALTER TABLE ONLY public.wh2_preparation_form DROP CONSTRAINT fk_material_code;
       public          postgres    false    231    4764    227            �           2606    71429 %   wh4_preparation_form fk_material_code    FK CONSTRAINT     �   ALTER TABLE ONLY public.wh4_preparation_form
    ADD CONSTRAINT fk_material_code FOREIGN KEY (material_code) REFERENCES public.wh4_material_codes(mid);
 O   ALTER TABLE ONLY public.wh4_preparation_form DROP CONSTRAINT fk_material_code;
       public          postgres    false    4768    228    232            �           2606    71444 %   wh2_receiving_report fk_material_code    FK CONSTRAINT     �   ALTER TABLE ONLY public.wh2_receiving_report
    ADD CONSTRAINT fk_material_code FOREIGN KEY (material_code) REFERENCES public.wh2_material_codes(mid);
 O   ALTER TABLE ONLY public.wh2_receiving_report DROP CONSTRAINT fk_material_code;
       public          postgres    false    4764    227    233            �           2606    71458 %   wh4_receiving_report fk_material_code    FK CONSTRAINT     �   ALTER TABLE ONLY public.wh4_receiving_report
    ADD CONSTRAINT fk_material_code FOREIGN KEY (material_code) REFERENCES public.wh4_material_codes(mid);
 O   ALTER TABLE ONLY public.wh4_receiving_report DROP CONSTRAINT fk_material_code;
       public          postgres    false    228    4768    234            �           2606    71473     wh2_spreadsheet fk_material_code    FK CONSTRAINT     �   ALTER TABLE ONLY public.wh2_spreadsheet
    ADD CONSTRAINT fk_material_code FOREIGN KEY (material_code) REFERENCES public.wh2_material_codes(material_code);
 J   ALTER TABLE ONLY public.wh2_spreadsheet DROP CONSTRAINT fk_material_code;
       public          postgres    false    227    235    4766            �           2606    71490     wh4_spreadsheet fk_material_code    FK CONSTRAINT     �   ALTER TABLE ONLY public.wh4_spreadsheet
    ADD CONSTRAINT fk_material_code FOREIGN KEY (material_code) REFERENCES public.wh4_material_codes(material_code);
 J   ALTER TABLE ONLY public.wh4_spreadsheet DROP CONSTRAINT fk_material_code;
       public          postgres    false    4770    236    228            �           2606    71511 "   wh4_transfer_form fk_material_code    FK CONSTRAINT     �   ALTER TABLE ONLY public.wh4_transfer_form
    ADD CONSTRAINT fk_material_code FOREIGN KEY (material_code) REFERENCES public.wh4_material_codes(mid);
 L   ALTER TABLE ONLY public.wh4_transfer_form DROP CONSTRAINT fk_material_code;
       public          postgres    false    4768    237    228            �           2606    71524 "   wh2_transfer_form fk_material_code    FK CONSTRAINT     �   ALTER TABLE ONLY public.wh2_transfer_form
    ADD CONSTRAINT fk_material_code FOREIGN KEY (material_code) REFERENCES public.wh2_material_codes(mid);
 L   ALTER TABLE ONLY public.wh2_transfer_form DROP CONSTRAINT fk_material_code;
       public          postgres    false    227    238    4764            �           2606    80212     wh1_spreadsheet fk_material_code    FK CONSTRAINT     �   ALTER TABLE ONLY public.wh1_spreadsheet
    ADD CONSTRAINT fk_material_code FOREIGN KEY (material_code) REFERENCES public.material_codes(material_code);
 J   ALTER TABLE ONLY public.wh1_spreadsheet DROP CONSTRAINT fk_material_code;
       public          postgres    false    4751    218    216            �           2606    71478 1   wh2_spreadsheet fk_material_code_to_material_code    FK CONSTRAINT     �   ALTER TABLE ONLY public.wh2_spreadsheet
    ADD CONSTRAINT fk_material_code_to_material_code FOREIGN KEY (material_code) REFERENCES public.wh2_material_codes(material_code);
 [   ALTER TABLE ONLY public.wh2_spreadsheet DROP CONSTRAINT fk_material_code_to_material_code;
       public          postgres    false    235    4766    227            �           2606    71495 1   wh4_spreadsheet fk_material_code_to_material_code    FK CONSTRAINT     �   ALTER TABLE ONLY public.wh4_spreadsheet
    ADD CONSTRAINT fk_material_code_to_material_code FOREIGN KEY (material_code) REFERENCES public.wh4_material_codes(material_code);
 [   ALTER TABLE ONLY public.wh4_spreadsheet DROP CONSTRAINT fk_material_code_to_material_code;
       public          postgres    false    228    236    4770            �           2606    80217 1   wh1_spreadsheet fk_material_code_to_material_code    FK CONSTRAINT     �   ALTER TABLE ONLY public.wh1_spreadsheet
    ADD CONSTRAINT fk_material_code_to_material_code FOREIGN KEY (material_code) REFERENCES public.material_codes(material_code);
 [   ALTER TABLE ONLY public.wh1_spreadsheet DROP CONSTRAINT fk_material_code_to_material_code;
       public          postgres    false    216    218    4751            �           2606    71300 %   wh1_outgoing_report fk_material_codes    FK CONSTRAINT     �   ALTER TABLE ONLY public.wh1_outgoing_report
    ADD CONSTRAINT fk_material_codes FOREIGN KEY (material_code) REFERENCES public.material_codes(mid);
 O   ALTER TABLE ONLY public.wh1_outgoing_report DROP CONSTRAINT fk_material_codes;
       public          postgres    false    4749    216    220            �           2606    71388 %   wh2_outgoing_report fk_material_codes    FK CONSTRAINT     �   ALTER TABLE ONLY public.wh2_outgoing_report
    ADD CONSTRAINT fk_material_codes FOREIGN KEY (material_code) REFERENCES public.wh2_material_codes(mid);
 O   ALTER TABLE ONLY public.wh2_outgoing_report DROP CONSTRAINT fk_material_codes;
       public          postgres    false    229    4764    227            �           2606    71401 %   wh4_outgoing_report fk_material_codes    FK CONSTRAINT     �   ALTER TABLE ONLY public.wh4_outgoing_report
    ADD CONSTRAINT fk_material_codes FOREIGN KEY (material_code) REFERENCES public.wh4_material_codes(mid);
 O   ALTER TABLE ONLY public.wh4_outgoing_report DROP CONSTRAINT fk_material_codes;
       public          postgres    false    4768    230    228            ^      x������ � �      v      x������ � �      b      x������ � �      d      x������ � �      f      x������ � �      `      x������ � �      h      x������ � �      i      x������ � �      k      x������ � �      m      x������ � �      o      x������ � �      q      x������ � �      t      x������ � �      j      x������ � �      l      x������ � �      n      x������ � �      p      x������ � �      r      x������ � �      s      x������ � �     