PGDMP          
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
    public          postgres    false    240   %�       b          0    71291    wh1_outgoing_report 
   TABLE DATA           �   COPY public.wh1_outgoing_report (reference_no, date_outgoing, material_code, quantity, area_location, id, deleted, status) FROM stdin;
    public          postgres    false    220   l�       d          0    71306    wh1_preparation_form 
   TABLE DATA           �   COPY public.wh1_preparation_form (reference_no, date, material_code, quantity_prepared, quantity_return, area_location, id, deleted, status) FROM stdin;
    public          postgres    false    222   ��       f          0    71321    wh1_receiving_report 
   TABLE DATA           �   COPY public.wh1_receiving_report (reference_no, date_received, material_code, quantity, area_location, id, deleted, status) FROM stdin;
    public          postgres    false    224    �       `          0    71272    wh1_spreadsheet 
   TABLE DATA           v   COPY public.wh1_spreadsheet (id, material_code, no_of_bags, qty_per_packing, whse1_excess, total, status) FROM stdin;
    public          postgres    false    218   ��       h          0    71336    wh1_transfer_form 
   TABLE DATA           v   COPY public.wh1_transfer_form (reference_no, date, material_code, quantity, area_to, status, id, deleted) FROM stdin;
    public          postgres    false    226   ��       i          0    71362    wh2_material_codes 
   TABLE DATA           `   COPY public.wh2_material_codes (mid, material_code, qty_per_packing, area_location) FROM stdin;
    public          postgres    false    227   �       k          0    71380    wh2_outgoing_report 
   TABLE DATA           �   COPY public.wh2_outgoing_report (reference_no, date_outgoing, material_code, quantity, area_location, id, deleted, status) FROM stdin;
    public          postgres    false    229   ��       m          0    71406    wh2_preparation_form 
   TABLE DATA           �   COPY public.wh2_preparation_form (reference_no, date, material_code, quantity_prepared, quantity_return, area_location, id, deleted, status) FROM stdin;
    public          postgres    false    231   S�       o          0    71435    wh2_receiving_report 
   TABLE DATA           �   COPY public.wh2_receiving_report (reference_no, date_received, material_code, quantity, area_location, id, deleted, status) FROM stdin;
    public          postgres    false    233   ��       q          0    71466    wh2_spreadsheet 
   TABLE DATA           v   COPY public.wh2_spreadsheet (id, material_code, no_of_bags, qty_per_packing, whse1_excess, total, status) FROM stdin;
    public          postgres    false    235   `       t          0    71516    wh2_transfer_form 
   TABLE DATA           v   COPY public.wh2_transfer_form (reference_no, date, material_code, quantity, area_to, status, id, deleted) FROM stdin;
    public          postgres    false    238   t      j          0    71371    wh4_material_codes 
   TABLE DATA           `   COPY public.wh4_material_codes (mid, material_code, qty_per_packing, area_location) FROM stdin;
    public          postgres    false    228   �      l          0    71393    wh4_outgoing_report 
   TABLE DATA           �   COPY public.wh4_outgoing_report (reference_no, date_outgoing, material_code, quantity, area_location, id, deleted, status) FROM stdin;
    public          postgres    false    230   �      n          0    71420    wh4_preparation_form 
   TABLE DATA           �   COPY public.wh4_preparation_form (reference_no, date, material_code, quantity_prepared, quantity_return, area_location, id, deleted, status) FROM stdin;
    public          postgres    false    232   4	      p          0    71449    wh4_receiving_report 
   TABLE DATA           �   COPY public.wh4_receiving_report (reference_no, date_received, material_code, quantity, area_location, id, deleted, status) FROM stdin;
    public          postgres    false    234   �	      r          0    71483    wh4_spreadsheet 
   TABLE DATA           v   COPY public.wh4_spreadsheet (id, material_code, no_of_bags, qty_per_packing, whse1_excess, total, status) FROM stdin;
    public          postgres    false    236   c      s          0    71503    wh4_transfer_form 
   TABLE DATA           �   COPY public.wh4_transfer_form (reference_no, date, material_code, quantity, area_to, status, id, deleted, new_status) FROM stdin;
    public          postgres    false    237   �      �           0    0    material_codes_mid_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.material_codes_mid_seq', 290, true);
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
       public          postgres    false    4768    230    228            ^   �  x�MW[��6���'H���O�3�zW�dǎ�r�s�����ϸ� ���8��#�q������±�����|�/�pL�5�-���: n4Ǧ�����pj��2�[!*DcY%�w�{�k�ׅ��[4 e1���+& Me �%�zm ç^~Z8}nƼ��|�>�8�K��{"�&��M ����٣H�[ԆJ�|�FDw	f�J�0+kT�<G�!`�L.!��4���!\|��Kb���U#���l᧚�O&���+v\�S��Tܜ��q	�2� ��k�T�� ���	���#�>L���$�i��T����Zy�:�� �S��!q�@�����,ѐ5��h�m`��|Vf%�M�Ϣ���+֬2pa��ÌkzۘìF��B���jsb޸�s��օY'�LϠ���4��ZK <c�a��U �f �jXT�� �$�r�E%�hQu��@b^ׇ%�l
��?��,b��>�x�9����d�|��I�]�������H
k��9�C'T��� �nkX��	��M� J�<��h�\@��~	��V�&&���(g��J7��P������M������M�6�>�|
�9x֯��[V	�H8����
Ix&k@������`��b���/����C^��D-_g�(l~�
�M�1�ڊ˭���bm��b��u�8l���n�<7G�ܔ赙��p��]�a3��p���`ٶ�4��^�g�ILD������R*�;c4	�����20�(c�IWO'���?
ڟ/��_<�ُ�����e�h ��_!���]��r_)��_)3}{��U:��B��I�|T��Zn�<B	vVQ
��Ԃ޷��~���!ʁZMi_t�"�`M�N�J"X�&����5���Т�:�BR�������A{M�f��)�':	��!&�M�`$���`܂������+y]���ss��?��]���7��OA`n�Q0���k\���x�~j���q�NE��n�+%"��T@���Yqd�^���ݔPEȀ��E+e&/���77!
��Fw��΋|����,}u���f�M]��ƺY�+�v�*-\��ԁ��Ǭ�n&7crWHKi����M��52��
Y�t5����T[�.2I_����Yd�TV:/�Ff�;�8��Ϋ#@vd�4D�M� �n�g �cS��l�)*G��~�!Nn:/e��3��ˌN'T�ͬ�ڻ��n�]��w���Y�N��~��*���}����������H]1�_�(�����0ݮ��)܎��p?��")|χ�������?m;~�+ n��*\���D�}�z���Y���l{��m�}�>	���w�?���ˋy���|���kϏ�q�(���>�>��Ɩi�?�'�����߇���l���o�4���O���[������?'x9/      v   7   x�3��v��q�Q�N�FF��F��
�VFV�&zF���Ɯi\1z\\\ A
�      b   o   x�}�;
�0��zs
/��n�>N�ll#v��� 	F��~�i�$�!9,1�,@ݰ�9l�Ϙ����F��K���N_�{����m�zyy������5�{ŗ�y_cv�A�      d   %  x�u�[j[A��ǫ�"F��u]B_��K
!������69:$��yf�Oұ�"U�c�Ǫ�?�R˷���������Z~��������U�Hn��3H�p#�+q�d�M<_i��>e�*@XY�R
�4�eE�"�Sʊ6R)*�"7Rn��ԥ�tx��[�L�cb�ʨnctH�L�����O���oˮ'f�ݹ
#�V����ԾV��%j4S!V�'���z�R!�H����l�Z�,�l7�D���uxjC��0΂����A��z�wl�00\i��:�AQ�x����h�IX�^�lZ^�b�"Z��ka�]�fh*+����.x�Q�M@�j���NƁ�M@�U���zFnD�օ+���
oD�/H������C"tQ\I�R�À�aڗ�p�Z�6`|;1gB�uoA/n��x�1}�ia���%^�2Ɔ�m��^��R�0�0V�p�tn/u�h���R8�2�LdG+{xь�K}�s�� ���?i���6L��	���58�*����!�ڀ�B�(5��T�q{�"�kO�*��*�-{&ua���dIM؆,��490���x�
�B�	ˇ$48������':$��i� # �'�N�׍��dz��O�=���CS��>����5���5U�G�4��\�i�c�/_4���Ѻ�PB��������^�%��<�ϗ����������������뫏���E��^�16������n�6ufȭ�w �U2Ļ�+xD4E��VG�Rd�	t�h����#�;�N��_��!       f   �  x��YKn\7\S��L��g�!�l�h'p,@�s�T5�2o����7~Ru�S�lvQ%[�)�)HV���l��������ʭ��`�c������J�?�E6c��?�M	���K�ԐG\>LU6ؚ�h+��0���|W]ٌ��a3��#�؃
�����I&�%��˙Dn++�sc�J��9��g5��������R<g���(�s�8�{ϊ�<���Q,�r\#��0Y!��W$�D�&�Y����CE<���MQ 7�}�1��]� x"��EQ`F�"�0 _�����-�] �kF��.�S�P�*v����U������"��*f ��m� ���6�Z �tq�- ��w��P[�̻��
G9�\'A�`��&�,LCR�"�y�hLĦ(o��KOS���{�o�t�nGF7E;�G�U�in�x��|,[1�}��w��j)2�MqoC�����ΩaE̅���^����݋.�WTóyM�h��~D�+��]*���ht�3�mղc��p�������,�5E5c�l�9Cю���pСH����a(�ደ�2�:�R=fR�ùԑvZE< \��gS���b�X��X�X`�0��`��X�k*�����T<�j5�����f�D�2a*��9㢧b �/S� ���T4��L�d �O�T؍�T�MB�b�	KQ`���+,��b���)�[��(^�Ͷқ)�1ߺA������s�"��Ӎ��[uҗ"�G�F�������y�${>x��%�T/��EI|K�1��$I	�|H� /���0,4�J�
�ض��,�g���^�a[ȋ��?|�|z����W�*G��Y��Pv��ܰ)�ҒTn@��c[顰��Fk'�V��1{\�C'�����i�lT�mj�o@�Q�Mf ��ط�L8
뼯$ӢH�i/^��9aZ7ɇ0���Eޤv&��k9�R<1��w�IM׮�s&%4�5}�RD���<$�@�~�W����K�I%MuH�iۂ{/K2��.�o1��H/1y��*�>(Zdj�ױ���<h�B��[����D��J&�6���Ф�&§���%Q<����M�p"��3�ĉ�ݱ���D^J�q"��?�'�_˂��DJM#�m'���zb���'A�~��D*o�m&A�~��T�D�k�HR����K]N$m%aR��|����:��.2@F�{v��Zyn��V)Չt�ϟR�1W�&�:^���R�i����4����,�\�t�����/O�����?�����/���o&<G\�y���Ƨ;O)�9@;ZF���^'���<6GNI-O�Z�����n>�������%/�<��<��������]JxN�tt1gR�s�:QR���9��ǒ�c��_sL*y΁6f������n���Vq�o������˯_/O)�����=�7�yM�s^[o��cC�ӯ�T�<����޸��qv�4X+k���U�B�y�HC
?�<��x���k�{��m��������K�ޫ�}���Н�ѫI/>����zu�|�gh؟�ea��9�4������TR�?N&�d�J:G�����.�%��N�Z�'RH>>�wB������KÝ5՛�p�{��z3I�*�_����?���5      `   "  x�uX�n7|��B_@���8��X�#(���%X�]1$��T��8�m?��j�žqR���7��m���ݗ/�ߤچ���B�0��D��������w��ww��w.lj��E��==�z�|����/.&_�WѪ�kl�y�9����K��ƕ�p����+�\p���cR�LS]��;�B��]1{l>'�;����|SE�-`�K��IN@�����n����0�5w�S�^�]�5�v�������pϱ�|ןPd,V|�����8�3E�Ü0��P��*�A��=� �ə�K���F�F�v-}iW3���t�������_w������׿���_��ߗ�ź�JG��iq�
v�|��WD��g�h(��5���s"pK���G��3��ƨ����&vX�C�aZT���!���zX��¨�C��>��M@����Tg,����'�o�+Nv�Pފ����M�]w嬊Yť�R	����]
u�&61���m��ŷ"�C��F�QO��h�p�)��Z(OH� �V:I�}�c"�
,͜��d�I�뙙��Eg����7i�.BW6��O��O����+��C�E�_�k���'"[�%�����J��t�� �I��M�����D�����`4/"�Chl���"��4n�"�t� ��]�,}��υzI��U��^���M6�K�߬aP��ڒ6�!q�<H�|b�)�3�y��0\��s=��y��u�7��'���:��Ly��#�6���
�K�G:Ծnvocq���~��l����W�սM���^�"��LE��g_��C��C]arý�� ܘ�=�ձ���]��5qPS+x��F��.��ĳ��[(�#C�l�"���d����Dd�{����XlOq�TYFS�n��*�e�ՅB�އ��W�^�M
Sj,Qi�=���cϱ��,���0Y�:�.��W�q;�:A۠�Un��!��<gz+�|�gB�Ա�b�D�!�GdR�I��v�o�B7�!6�l��	��9��B�,�d�C�١��6�����ۉ��@p��CC���U�L9���f����L!����-�<A �8I.RJ�U}� ��V=K���eV�,�j[�a��㗀���ly� ��60h	p"��\e�]�D�.4��C4
{�4�D�V$EF#-�H%��W[z"�A�!���SD:��3Ef���ȋ q���x��(�e��]N��H���quqo�Z%ї��z�p�-J�ztWi(��ԍK縳���ɤ�%�8_�'OSb"����P�(��0G�|����v|�!q� �p=�"���t_�hLW�������������XO��4ʙ�}�R7,���W8I��,����#~�� ����>xq�%&�"�MhyRZ�{��AYq%��S�?�r�4�H�)�����(n���!�a���0'J��@�o�����JR��1w�/���r9�[:vr����j�!~�}��HĪ���-��9�
��u#�ܪ�A��=�Eg;�/��%U�p��V��$�\�}21M�ӄ�'�kU��&]L����!�!f �.͋�N���@J8����91`b^�m�=@�*���r�����~z*⠍^�V,�gA�z_/���Eh�zB��0M�4Y%1)���
úv(k�O�4�2�X`�v"p�T�����H,�0�tĴ-�$}����q�ߧ�>��R4Eŭ��P��h�wJ`Z��0MD�:�~�Zٖ��L�5�\�����5\��&�o����]c�)���a��x���ó�K�����!���Z^E���~(R#V;�S��P���p�_R�{I��8�!%23��9���U�4TK{ Ӥ�D>�ȧ zn<�-��S���c�O�gN�c}�1Lx�$���({��0����Y���aô�c���m�Z�z���Du�sRD�b#y;|���������������5�e��G����������uZ�<����l_�Hx��n��[޶7�*ސ�Bڳn:$ݎ�vC�T�"�(O��|������v,��.��0�Aa��g���m�/�͛7� �3��      h      x������ � �      i   �  x�]WQ��8�v�"'�E�����t�I�#�dxo��-�Jl��*lI���׵�r~޼�ƴ-k,��X�m�Խ���u��er�V��I��TX�6w��=�zRj�k]äT���HS�F��ꏤ"�m�q���V�;�Z�5o�V�|�N^m4��:��r���FIV�0����� �6�n�^;J����|9���h��Ǯ�*\T�V>���]��H��ՆH�Eښ���T�!�/����' �ݽ�B�7��V�|W����^Î%E�!Y��"
�H��H'E�@N��)C�`����E54��?ؼ"~��碹��=�UO"�(�y��ax"�,�k����M�H�=�(��g���ʝ;(��yj~bMw��[�5���N��cwTM��Y�ޟY;����+�k��BP����wBB@�@# ��A?�/H�~d��~����F
�g>7b�?X>s���l��;�$dw!+��l�Ev��K/k��+=����$�w9L*6n����l��`�Ya�7E������^S�����00�P1�iE�C�6�Bz�%�)0�����X닠z�b-�������m\��*m��X!�HC�8OCy^v��V�&Rq�%��[d��>�^/�Ux���dJ����Z�IɍA��CY��?���(��U'���{�5U��TUp���XiV��N�f�-0��V�-����r�D�j�Wꊜ�H�s�s&K J��0�O͎f� e�ƈ����q������r���n���~��i|7�-�qLU��/q�DZBH��H
1�����<�`.;��pF;�>9I�=w��p�΄d�����:32�v��p q9�@F���2�ŜʰK�3Bĺ�E��r��-g��C��G��	�\��pĺl�nv,���W�ln-=Z�Br3g��	���	�;��UI�d�<$f� Hs��R(� ���x��`�~+x��z���f돂����+u��)u�A����<ﭳ�h���)���v�!и_�\��e5�>��%C��N��A��2����,i4����Y�V�Փ���-�hE�n�C��X�uuE� 奥kؿX�ё���m:�ظRm�46*ۃ뱎X6���qf�!���	��#�������<�|C�V$b�El����ذ�HsF%�j{p7X{�&�3��ƴ[��ї������r˞��زg=.��Y���XT��e�\d�k �X�h�/|�2H/{E������B**����D|١u�#e��᳹B�<�ϖ�`�U泀�/�#��o7Me���T�N[Sy%���!<�K�'�K^G��� ��V��H3���г�W���4���ꅡ��E[:�f�{P��<�F�����"������l^G;�;���d�lՅ�<��&+�R�����u��Rx׺za��)�k�Ḣ�R��N��O!�2%C�]�p�<��~9m�������ܲ�      k   H   x�362�4]0�4�442�O,J��/-NU0�4�L�t��O�262AVidl�i���̀:��1������� ��      m   .   x�324�4]0�4�42BNsKN#N#�4N����=... ��      o   �  x���Kn1���)|��C�^�G�&���H✿�4H<��ƻ�?j�O$'�Z�I��$I)�?��~_�����셤V�M?/��N�g�L"��)#�PKT�@�!�4�qBG@YO���Rs ��Nl��&4ߣ���98/ϧ���iy�/��������OL#�1б�O��,M��L^f5�-\�? �94�8���F:�|{�y2A�K�.��Z���D�o���aF ~g:���u�r��v���	��KVHl�Tg"�k�4 EZ#�I ��#`6�*+A&�Ĳ�1
V���9�
�VG���˜n�}���lIErټ�m��"�l}5��s_'ؠ�ҼQ�>ý�V9W?&7��q����0��ݯ��o6v4�w!�y��-�����?��ND���� ���@m�S݉����r_����W����a���'vjC      q     x�m�ۊA���b�@��ϹS�F׍����,($���y�T�t9�\t�_u��"�f��[�/����<!뽐cBO�$`N�3�zCa��#�˧��Q@*(�(��K2�z���H�PP	cAR���S���\��L�>|�z&IĚ��T^�D��zh+�:q��l7�f�2����~��|~�/�˿��Ϸ����7ame�׎%G�f�[¦���z�}���y_�* c���8��VZuS����Tl�uR�Υ��T������d����R�t����|�n�5��Pz�l�W������Y<�iLؙt��S���D��M7cӉ:�uq����^�+)&���0:��Pf�w\Wġ�?���T�����MJ��!�3���$���>K����X����%�R�R�mR\AƁD���0�4�;�Z�csX�l��t��U��7B�T���*�gTj��X���q�S�C�e�� Ig�������P��mPՇTr��m���d2��b�      t   q   x���;
�0��zs
/��yy�`c#��������axDrp��Yt�<1 �c��u��P�B]�Ͱ��r������LPyRyʒWt~4��e����_�C��랅O�1�?oK�      j   �  x�]WQ��8�v�"'���`��M�i��H���7�?ǖ@�L�OUزlK%�]�\�~����0k��0����0�:���c��c8����l��T{�lN�`��ֻ)Vj7�ꦭ�4�jG�^?$��ȗ�V��_N��x�X�k��\N��^։
� �i�#�r����ܸ9�r[��l��n�z��V�rs�|�u�`��R��գ)�n�4n	�����[c(�-<�R`�\_U 5�h	@!��mXt��w_!�%���h���R��*��� Ɔ˗o��1S��EF�F�ָ5U-�-� l�����ŭEoÇʭr�� ��,�P�oQ���D�
�A��Vq�(b(H�U\��XW�%f��%����:��<�����6~�h�/�B}��CiG�R ��7�݃��\�w�9H�$F���� w��zP[|Ln�|��m\3 �׮��D�¢��"+�o9���	��-�rE�>���	N�!cBM�9�eZe��Idļ�oLQ����aq���B&��9���;(��4�LC�f��dc�Gc�+�-dtv^���q붏i���P}�w���2.����q����Ev_�e<��k��_t_��<���m�;�š/1��#3T��Q$����sS�ϵ���O����4�_T����]�i:���j׏�'��6=L��W�l��v��#yd��zFn�ԩ�4�:��Cp?�:����RG���Rij�R?��B�9Jq�!���Z��<\�4�W���ӣM�Y�I#�U�fcJe��Q��V�=�h�[K!������U�7�gl|KTl|��� ��PpPi���y�y����gMzT��nD�=�U�=����x����q\���q�����Vb���$���'��d<I,l��6�txQx+J/��
Rz�S���y���	���}}�B����r#�;z���u6 ��z�w�t�x>u��,ԧ�Ր
��Lf|�Zn=Mj���x>��w0���pgB�Y��ĊkI_<��yc���U��<#�a�]�d�#�}6-+�)��֬*e���>�̠�<������}�1�`B4�z���(}�`,ޙ`���h���p�Y���@���������Y�*�,h�|��>ۻ6kĻ��C�=J`�X��W��2X�`�d,K,����6�����lW���.��`[tg�i�m�6�w~�����WO=�\Ç�CR�w+��J���ñ�ΑQÕ׃����t ��m�5d�0s�H�a~jQt?M����c��^n�bچ��q~_홆T�1��4�͠��|f�Q��,M�K�������{���"-�I��ޛ��ޜ,jw��~�����d�N�q��2۶.�N��'{dɿ�Y�FK4�3��V�;��9�4�Cɼ�6�V�H��^�P�5ћ��GL���k����)���2u��x�\@�-�&�eX������������xR�      l   M   x�3624�4]0�4�435�O,J��/-NU0�4�L�t��O�2FSj����RN��)�Z�j����0�=... >�$�      n   <   x�361��4202�50�50�42�440�4�O,J��/-NU0�r�q���p��qqq 'Uc      p   �  x����n�7�׿�"/�ׅ���붛l��E
�1����R�H�Q]^8�G�>�CR����������y���2��z��������\�a���>�W5_��,��d �[��b]9���U��8ԫ��G�'�v�{�*�d2���U�}�yEzbZ��P���	j���%NP븪%���(	�%���#��tb����Ήm��R�_�ɪ^9����L�5��������]�>isBlإNw�� ��-(�s�ھ�r�މC��x�r&�4i5-�G9�6d[��	�!B�>�	��L6��f�X��(�1ZO�{e �'½a�6'��:'��{v�9��:f���W^ϱ<����A�k���\﵍N�����Q'�7�C��	3>�C5͘{܈����ڡ����J-l4c����h2A��l�@ 7Ҧ1�*ٲ;m�&��</h�ET�&��,V�;1���
借޾�d�r���;IȨ��	~����~y�����}����_��
r���Iܐ��[�5%k�Ձ`��6
Ě���%�<<[KN�K�,��S��*�%n��5��L��������q�wa�LT��.��5�.��,�2��; �H�m$h�(^��DMo3S�M$�B��h�����P�2ɘgC�F�(L�T����7+���� ]��9{'�#rIڐ�]+/lЕy_��+_Gp�����}�#8W�}AҢ')���\��(p;���\�����w��re��.��	̕i_��f��)9g6Q��>%fDV�92lJ�LvX��D�\/�ZѭM��Ɏ��cK�L��`7�[*T=��ᙄ��/l4w��$o&~�{VX�6���,l$l�}ͻ'[6��ǒ�\��R������H��\w�-�����-�L��,$^N��\� j?�嶒��	��m[I����Ʒ���bz��-87�+�(�0���b�'�0���d�ҍ꒭�����%�4M#A���0�b!56W���&������0ب/�]C�q�?ӱ����:�J�c���I��,��y�	�Qq2��������9j���N!��?�Fb�̠d�Vj<l�_�ٖ�t�(2�ېԆ[Iꅪ����x��������0V��)5��������-{�QH��KMsZ�jPlT��~��n���kOaݎH��5`��~)Pc�n�5���f�F	*4L�O���F*0�i�v��{
j�n#ț7.�>�͵~�V3��Ѽu�#�a$���.p������h޼�{�$����f��Fjz4
L���NM���S,$x�70���n�74����������_�#͛�a�����犊���p�$��J�,��c!ɞ�h��_��*�*S���x;�������SBM��JOZ*�j�4��ʜ�O͖�ZCݛ�_���Jc|��uR���:�ǳ4b)ɜ*cx�5X�k�y����\`��~�Ũ��\a����gs�����Ms�a��{w5n���&��i�\n���¥�Mc�א#w�$�w�$�q�l�ո�]�:��'�7��R�>>V����s<f5ov%8��=�}q�%
n՘��@�K�B<����]��V�gU#hw��#�0R3hw�|t��@����/awtj��?|k+�5cvokF}�P���S���%N��������%�'з�186��3��ѷ��AI���W���[���6~k�͎����ٞ������-�F~������_>�����᧧����o-�P      r      x������ � �      s      x������ � �     