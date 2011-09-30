SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;
--
-- TOC entry 339 (class 2612 OID 16442)
-- Name: plperl; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: tarif
--

--CREATE PROCEDURAL LANGUAGE plperl;


--ALTER PROCEDURAL LANGUAGE plperl OWNER TO tarif;

--
-- TOC entry 340 (class 2612 OID 16445)
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: tarif
--

CREATE PROCEDURAL LANGUAGE plpgsql;


ALTER PROCEDURAL LANGUAGE plpgsql OWNER TO tarif;

SET search_path = public, pg_catalog;

--
-- TOC entry 22 (class 1255 OID 16633)
-- Dependencies: 340 3
-- Name: addinternet(inet, integer); Type: FUNCTION; Schema: public; Owner: tarif
--

CREATE FUNCTION addinternet(selipaddr inet, acctime integer) RETURNS integer
    LANGUAGE plpgsql COST 99
    AS $$
DECLARE
        devid integer;
        result integer;
--	secs text;
        newdatetime integer;
BEGIN

/* функция предоставления доступа  в интернет
принимаемые параметры - ip устройства и время предоставления доступа в секундах
*/
select id into devid from devices where ipaddr=selipaddr limit 1;
if (devid is null) then
RAISE EXCEPTION ' Device not finded ---> %',selipaddr;
        return -1;
end if;
--select cast(acctime as text) into secs;
select into newdatetime date_part('epoch',CURRENT_TIMESTAMP)::int+acctime ;
insert into seanses (deviceid,accesstime,servicetypeid)
        values (devid,to_timestamp(newdatetime) ,1) returning id into result;

RETURN result;
END;
$$;


ALTER FUNCTION public.addinternet(selipaddr inet, acctime integer) OWNER TO tarif;

--
-- TOC entry 23 (class 1255 OID 16671)
-- Dependencies: 3 340
-- Name: canaccesstourl(inet, text); Type: FUNCTION; Schema: public; Owner: tarif
--

CREATE FUNCTION canaccesstourl(selipaddr inet, url text) RETURNS text
    LANGUAGE plpgsql COST 99
    AS $$
DECLARE
        result text;
        did integer;
BEGIN

/* функция проверки возможности доступа в интернет
        принимаемые параметры - ip устройства и запрашиваемый url
*/
if isblackdomain(url)=true then
-- если домен в черном списке то перенаправим пользователя на какойто url
        return 'http://gu.spb.ru';
end if;

if iswhitedomain(url)=true then
--если домен в белом списке - дадим доступ к нему в любом случае
        return url;

end if;
select into did  id from devices where ipaddr=selipaddr;

if exists (select 1 from seanses where (servicetypeid=1 and accesstime > LOCALTIMESTAMP and deviceid=did) ) then
        return url;

else
--если платный url
        return 'http://192.168.0.150/pay.php?url='||url;

end if;



RETURN result;
END;
$$;


ALTER FUNCTION public.canaccesstourl(selipaddr inet, url text) OWNER TO tarif;

--
-- TOC entry 19 (class 1255 OID 16446)
-- Dependencies: 3 340
-- Name: extractdomain(text, integer); Type: FUNCTION; Schema: public; Owner: tarif
--

CREATE FUNCTION extractdomain(url text, domain_level integer) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
v_domain_full text;
v_domain text;
v_matches text[];
v_level INTEGER := 1;
v_url_levels INTEGER := 0;
rec record;
BEGIN
SELECT regexp_matches(lower(url), E'https?://(www\\.)?([-\\wа-яА-Я0-9.]*\\.[а-яa-z]{2,6})', 'gi') INTO v_matches LIMIT 1;

IF v_matches IS NULL OR v_matches[2] IS NULL THEN
RETURN NULL;
END IF;

v_domain_full := v_matches[2];

v_matches := regexp_split_to_array(v_domain_full, E'\\.');
SELECT count(*) INTO v_url_levels FROM regexp_split_to_table(v_domain_full, E'\\.');

IF v_url_levels = domain_level THEN
RETURN v_domain_full;
END IF;

IF v_url_levels < domain_level THEN
RETURN NULL;
END IF;

v_domain := v_matches[v_url_levels];

IF (domain_level > 1) THEN
FOR i IN 1..domain_level-1 LOOP
v_domain := v_matches[v_url_levels - i] || '.' || v_domain;
END LOOP;
END IF;

RETURN v_domain;
END;
$$;


ALTER FUNCTION public.extractdomain(url text, domain_level integer) OWNER TO tarif;

--
-- TOC entry 24 (class 1255 OID 24863)
-- Dependencies: 3 340
-- Name: extractdomain(text); Type: FUNCTION; Schema: public; Owner: tarif
--

CREATE FUNCTION extractdomain(url text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE

v_domain text;
p2 text;

BEGIN
p2:=url;
select array_to_string into v_domain (regexp_matches(url ,E'http[s]{0,1}://([^\/]+)'),'');


RETURN v_domain;
END;
$$;


ALTER FUNCTION public.extractdomain(url text) OWNER TO tarif;

--
-- TOC entry 20 (class 1255 OID 16526)
-- Dependencies: 340 3
-- Name: isblackdomain(text); Type: FUNCTION; Schema: public; Owner: tarif
--

CREATE FUNCTION isblackdomain(url text) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE COST 120
    AS $$
DECLARE
sspos integer;
domainname text;
findeddomains text;
result bool:=false;
BEGIN
domainname:= extractdomain(url);
select host into findeddomains from blacklist where host like(domainname)   limit 1;
SELECT INTO sspos position(domainname in findeddomains)  LIMIT 1;

if (sspos > 0)
then
result:=true;
end if;
RETURN result;
END;
$$;


ALTER FUNCTION public.isblackdomain(url text) OWNER TO tarif;

--
-- TOC entry 21 (class 1255 OID 16513)
-- Dependencies: 340 3
-- Name: iswhitedomain(text); Type: FUNCTION; Schema: public; Owner: tarif
--

CREATE FUNCTION iswhitedomain(url text) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE COST 99
    AS $$
DECLARE
sspos integer;
domainname text;
findeddomains text;
result bool:=false;
BEGIN
domainname:= extractdomain(url);
--select host into findeddomains from whitelist where host like(domainname)   limit 1;
--select host into findeddomains from whitelist where  extractdomain(url) ~ host  limit 1;
--SELECT INTO sspos position(domainname in findeddomains)  LIMIT 1;
select count (1) into sspos from whitelist where  extractdomain(url) ~ host  limit 1;
if (sspos > 0)
then
result:=true;
end if;
RETURN result;
END;
$$;


ALTER FUNCTION public.iswhitedomain(url text) OWNER TO tarif;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 1534 (class 1259 OID 16516)
-- Dependencies: 3
-- Name: blacklist; Type: TABLE; Schema: public; Owner: tarif; Tablespace:
--

CREATE TABLE blacklist (
    id bigint NOT NULL,
    host text NOT NULL
);


ALTER TABLE public.blacklist OWNER TO tarif;

--
-- TOC entry 1533 (class 1259 OID 16514)
-- Dependencies: 3 1534
-- Name: blacklist_id_seq; Type: SEQUENCE; Schema: public; Owner: tarif
--

CREATE SEQUENCE blacklist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.blacklist_id_seq OWNER TO tarif;

--
-- TOC entry 1872 (class 0 OID 0)
-- Dependencies: 1533
-- Name: blacklist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tarif
--

ALTER SEQUENCE blacklist_id_seq OWNED BY blacklist.id;


--
-- TOC entry 1873 (class 0 OID 0)
-- Dependencies: 1533
-- Name: blacklist_id_seq; Type: SEQUENCE SET; Schema: public; Owner: tarif
--

SELECT pg_catalog.setval('blacklist_id_seq', 3, true);


--
-- TOC entry 1542 (class 1259 OID 16576)
-- Dependencies: 3
-- Name: codes; Type: TABLE; Schema: public; Owner: tarif; Tablespace:
--

CREATE TABLE codes (
    id bigint NOT NULL,
    phonecode text
);


ALTER TABLE public.codes OWNER TO tarif;

--
-- TOC entry 1541 (class 1259 OID 16574)
-- Dependencies: 1542 3
-- Name: codes_id_seq; Type: SEQUENCE; Schema: public; Owner: tarif
--

CREATE SEQUENCE codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.codes_id_seq OWNER TO tarif;

--
-- TOC entry 1874 (class 0 OID 0)
-- Dependencies: 1541
-- Name: codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tarif
--

ALTER SEQUENCE codes_id_seq OWNED BY codes.id;


--
-- TOC entry 1875 (class 0 OID 0)
-- Dependencies: 1541
-- Name: codes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: tarif
--

SELECT pg_catalog.setval('codes_id_seq', 1, false);


--
-- TOC entry 1536 (class 1259 OID 16533)
-- Dependencies: 3
-- Name: devices; Type: TABLE; Schema: public; Owner: tarif; Tablespace:
--

CREATE TABLE devices (
    id bigint NOT NULL,
    name text NOT NULL,
    ipaddr inet,
    phonenumber text,
    comment text
);


ALTER TABLE public.devices OWNER TO tarif;

--
-- TOC entry 1535 (class 1259 OID 16531)
-- Dependencies: 1536 3
-- Name: devices_id_seq; Type: SEQUENCE; Schema: public; Owner: tarif
--

CREATE SEQUENCE devices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.devices_id_seq OWNER TO tarif;

--
-- TOC entry 1876 (class 0 OID 0)
-- Dependencies: 1535
-- Name: devices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tarif
--

ALTER SEQUENCE devices_id_seq OWNED BY devices.id;


--
-- TOC entry 1877 (class 0 OID 0)
-- Dependencies: 1535
-- Name: devices_id_seq; Type: SEQUENCE SET; Schema: public; Owner: tarif
--

SELECT pg_catalog.setval('devices_id_seq', 7, true);


--
-- TOC entry 1528 (class 1259 OID 16388)
-- Dependencies: 3
-- Name: log; Type: TABLE; Schema: public; Owner: tarif; Tablespace:
--

CREATE TABLE log (
    id bigint NOT NULL,
    typeid integer NOT NULL,
    message text
);


ALTER TABLE public.log OWNER TO tarif;

--
-- TOC entry 1527 (class 1259 OID 16386)
-- Dependencies: 3 1528
-- Name: log_id_seq; Type: SEQUENCE; Schema: public; Owner: tarif
--

CREATE SEQUENCE log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.log_id_seq OWNER TO tarif;

--
-- TOC entry 1878 (class 0 OID 0)
-- Dependencies: 1527
-- Name: log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tarif
--

ALTER SEQUENCE log_id_seq OWNED BY log.id;


--
-- TOC entry 1879 (class 0 OID 0)
-- Dependencies: 1527
-- Name: log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: tarif
--

SELECT pg_catalog.setval('log_id_seq', 1, false);


--
-- TOC entry 1530 (class 1259 OID 16396)
-- Dependencies: 3
-- Name: logtype; Type: TABLE; Schema: public; Owner: tarif; Tablespace:
--

CREATE TABLE logtype (
    id bigint NOT NULL,
    name text NOT NULL
);


ALTER TABLE public.logtype OWNER TO tarif;

--
-- TOC entry 1529 (class 1259 OID 16394)
-- Dependencies: 1530 3
-- Name: logtype_id_seq; Type: SEQUENCE; Schema: public; Owner: tarif
--

CREATE SEQUENCE logtype_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.logtype_id_seq OWNER TO tarif;

--
-- TOC entry 1880 (class 0 OID 0)
-- Dependencies: 1529
-- Name: logtype_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tarif
--

ALTER SEQUENCE logtype_id_seq OWNED BY logtype.id;


--
-- TOC entry 1881 (class 0 OID 0)
-- Dependencies: 1529
-- Name: logtype_id_seq; Type: SEQUENCE SET; Schema: public; Owner: tarif
--

SELECT pg_catalog.setval('logtype_id_seq', 2, true);


--
-- TOC entry 1540 (class 1259 OID 16563)
-- Dependencies: 3
-- Name: seanses; Type: TABLE; Schema: public; Owner: tarif; Tablespace:
--

CREATE TABLE seanses (
    id bigint NOT NULL,
    deviceid integer NOT NULL,
    accesstime timestamp without time zone NOT NULL,
    servicetypeid integer
);


ALTER TABLE public.seanses OWNER TO tarif;

--
-- TOC entry 1539 (class 1259 OID 16561)
-- Dependencies: 1540 3
-- Name: seanses_id_seq; Type: SEQUENCE; Schema: public; Owner: tarif
--

CREATE SEQUENCE seanses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.seanses_id_seq OWNER TO tarif;

--
-- TOC entry 1882 (class 0 OID 0)
-- Dependencies: 1539
-- Name: seanses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tarif
--

ALTER SEQUENCE seanses_id_seq OWNED BY seanses.id;


--
-- TOC entry 1883 (class 0 OID 0)
-- Dependencies: 1539
-- Name: seanses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: tarif
--

SELECT pg_catalog.setval('seanses_id_seq', 7, true);


--
-- TOC entry 1538 (class 1259 OID 16550)
-- Dependencies: 3
-- Name: services; Type: TABLE; Schema: public; Owner: tarif; Tablespace:
--

CREATE TABLE services (
    id bigint NOT NULL,
    name text
);


ALTER TABLE public.services OWNER TO tarif;

--
-- TOC entry 1537 (class 1259 OID 16548)
-- Dependencies: 1538 3
-- Name: services_id_seq; Type: SEQUENCE; Schema: public; Owner: tarif
--

CREATE SEQUENCE services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.services_id_seq OWNER TO tarif;

--
-- TOC entry 1884 (class 0 OID 0)
-- Dependencies: 1537
-- Name: services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tarif
--

ALTER SEQUENCE services_id_seq OWNED BY services.id;


--
-- TOC entry 1885 (class 0 OID 0)
-- Dependencies: 1537
-- Name: services_id_seq; Type: SEQUENCE SET; Schema: public; Owner: tarif
--

SELECT pg_catalog.setval('services_id_seq', 8, true);


--
-- TOC entry 1532 (class 1259 OID 16413)
-- Dependencies: 3
-- Name: whitelist; Type: TABLE; Schema: public; Owner: tarif; Tablespace:
--

CREATE TABLE whitelist (
    id bigint NOT NULL,
    host text NOT NULL
);


ALTER TABLE public.whitelist OWNER TO tarif;



CREATE SEQUENCE whitelist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.whitelist_id_seq OWNER TO tarif;

--
-- TOC entry 1886 (class 0 OID 0)
-- Dependencies: 1531
-- Name: whitelist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tarif
--

ALTER SEQUENCE whitelist_id_seq OWNED BY whitelist.id;


--
-- TOC entry 1887 (class 0 OID 0)
-- Dependencies: 1531
-- Name: whitelist_id_seq; Type: SEQUENCE SET; Schema: public; Owner: tarif
--

SELECT pg_catalog.setval('whitelist_id_seq', 4, true);


--
-- TOC entry 1823 (class 2604 OID 16519)
-- Dependencies: 1534 1533 1534
-- Name: id; Type: DEFAULT; Schema: public; Owner: tarif
--

ALTER TABLE blacklist ALTER COLUMN id SET DEFAULT nextval('blacklist_id_seq'::regclass);


--
-- TOC entry 1827 (class 2604 OID 16579)
-- Dependencies: 1541 1542 1542
-- Name: id; Type: DEFAULT; Schema: public; Owner: tarif
--

ALTER TABLE codes ALTER COLUMN id SET DEFAULT nextval('codes_id_seq'::regclass);


--
-- TOC entry 1824 (class 2604 OID 16536)
-- Dependencies: 1536 1535 1536
-- Name: id; Type: DEFAULT; Schema: public; Owner: tarif
--

ALTER TABLE devices ALTER COLUMN id SET DEFAULT nextval('devices_id_seq'::regclass);


--
-- TOC entry 1820 (class 2604 OID 16391)
-- Dependencies: 1528 1527 1528
-- Name: id; Type: DEFAULT; Schema: public; Owner: tarif
--

ALTER TABLE log ALTER COLUMN id SET DEFAULT nextval('log_id_seq'::regclass);


--
-- TOC entry 1821 (class 2604 OID 16399)
-- Dependencies: 1530 1529 1530
-- Name: id; Type: DEFAULT; Schema: public; Owner: tarif
--

ALTER TABLE logtype ALTER COLUMN id SET DEFAULT nextval('logtype_id_seq'::regclass);


--
-- TOC entry 1826 (class 2604 OID 16566)
-- Dependencies: 1540 1539 1540
-- Name: id; Type: DEFAULT; Schema: public; Owner: tarif
--

ALTER TABLE seanses ALTER COLUMN id SET DEFAULT nextval('seanses_id_seq'::regclass);


--
-- TOC entry 1825 (class 2604 OID 16553)
-- Dependencies: 1537 1538 1538
-- Name: id; Type: DEFAULT; Schema: public; Owner: tarif
--

ALTER TABLE services ALTER COLUMN id SET DEFAULT nextval('services_id_seq'::regclass);


--
-- TOC entry 1822 (class 2604 OID 16416)
-- Dependencies: 1531 1532 1532
-- Name: id; Type: DEFAULT; Schema: public; Owner: tarif
--

ALTER TABLE whitelist ALTER COLUMN id SET DEFAULT nextval('whitelist_id_seq'::regclass);


--
-- TOC entry 1862 (class 0 OID 16516)
-- Dependencies: 1534
-- Data for Name: blacklist; Type: TABLE DATA; Schema: public; Owner: tarif
--

INSERT INTO blacklist (id, host) VALUES (3, 'kavkazcenter.com');


--
-- TOC entry 1866 (class 0 OID 16576)
-- Dependencies: 1542
-- Data for Name: codes; Type: TABLE DATA; Schema: public; Owner: tarif
--



--
-- TOC entry 1863 (class 0 OID 16533)
-- Dependencies: 1536
-- Data for Name: devices; Type: TABLE DATA; Schema: public; Owner: tarif
--

--INSERT INTO devices (id, name, ipaddr, phonenumber, comment) VALUES (1, 'kovalev', '192.168.0.100', '101', 'Kovalev test pc');
--INSERT INTO devices (id, name, ipaddr, phonenumber, comment) VALUES (2, 'demchenko', '192.168.0.101', '0101', 'demchenko test pc');
--INSERT INTO devices (id, name, ipaddr, phonenumber, comment) VALUES (3, 'terminalstend', '192.168.0.48', '048', 'terminal test pc');
--INSERT INTO devices (id, name, ipaddr, phonenumber, comment) VALUES (6, 'prokopenko', '192.168.0.118', '118', 'prokopenko test pc');


--
-- TOC entry 1859 (class 0 OID 16388)
-- Dependencies: 1528
-- Data for Name: log; Type: TABLE DATA; Schema: public; Owner: tarif
--



--
-- TOC entry 1860 (class 0 OID 16396)
-- Dependencies: 1530
-- Data for Name: logtype; Type: TABLE DATA; Schema: public; Owner: tarif
--

INSERT INTO logtype (id, name) VALUES (1, 'Ошибка');
INSERT INTO logtype (id, name) VALUES (2, 'Предупреждение');


--
-- TOC entry 1865 (class 0 OID 16563)
-- Dependencies: 1540
-- Data for Name: seanses; Type: TABLE DATA; Schema: public; Owner: tarif
--


--
-- TOC entry 1864 (class 0 OID 16550)
-- Dependencies: 1538
-- Data for Name: services; Type: TABLE DATA; Schema: public; Owner: tarif
--

INSERT INTO services (id, name) VALUES (1, 'Интернет');
INSERT INTO services (id, name) VALUES (2, 'Телефония');
INSERT INTO services (id, name) VALUES (3, 'Печать');
INSERT INTO services (id, name) VALUES (4, 'Email');


--
-- TOC entry 1861 (class 0 OID 16413)
-- Dependencies: 1532
-- Data for Name: whitelist; Type: TABLE DATA; Schema: public; Owner: tarif
--

INSERT INTO whitelist (id, host) VALUES (1, 'yandex.ru');
INSERT INTO whitelist (id, host) VALUES (2, 'gov.spb.ru');
INSERT INTO whitelist (id, host) VALUES (3, 'gu.spb.ru');
INSERT INTO whitelist (id, host) VALUES (4, 'gov.ru');


--
-- TOC entry 1838 (class 2606 OID 16530)
-- Dependencies: 1534 1534
-- Name: blacklist_host_key; Type: CONSTRAINT; Schema: public; Owner: tarif; Tablespace:
--

ALTER TABLE ONLY blacklist
    ADD CONSTRAINT blacklist_host_key UNIQUE (host);


--
-- TOC entry 1853 (class 2606 OID 16592)
-- Dependencies: 1542 1542
-- Name: codes_phonecode_key; Type: CONSTRAINT; Schema: public; Owner: tarif; Tablespace:
--

ALTER TABLE ONLY codes
    ADD CONSTRAINT codes_phonecode_key UNIQUE (phonecode);


--
-- TOC entry 1855 (class 2606 OID 16581)
-- Dependencies: 1542 1542
-- Name: codes_pkey; Type: CONSTRAINT; Schema: public; Owner: tarif; Tablespace:
--

ALTER TABLE ONLY codes
    ADD CONSTRAINT codes_pkey PRIMARY KEY (id);


--
-- TOC entry 1842 (class 2606 OID 16547)
-- Dependencies: 1536 1536
-- Name: devices_name_key; Type: CONSTRAINT; Schema: public; Owner: tarif; Tablespace:
--

ALTER TABLE ONLY devices
    ADD CONSTRAINT devices_name_key UNIQUE (name);


--
-- TOC entry 1830 (class 2606 OID 16393)
-- Dependencies: 1528 1528
-- Name: log_pkey; Type: CONSTRAINT; Schema: public; Owner: tarif; Tablespace:
--

ALTER TABLE ONLY log
    ADD CONSTRAINT log_pkey PRIMARY KEY (id);


--
-- TOC entry 1840 (class 2606 OID 16524)
-- Dependencies: 1534 1534
-- Name: pk_blid; Type: CONSTRAINT; Schema: public; Owner: tarif; Tablespace:
--

ALTER TABLE ONLY blacklist
    ADD CONSTRAINT pk_blid PRIMARY KEY (id);


--
-- TOC entry 1844 (class 2606 OID 16538)
-- Dependencies: 1536 1536
-- Name: pk_devid; Type: CONSTRAINT; Schema: public; Owner: tarif; Tablespace:
--

ALTER TABLE ONLY devices
    ADD CONSTRAINT pk_devid PRIMARY KEY (id);


--
-- TOC entry 1832 (class 2606 OID 16404)
-- Dependencies: 1530 1530
-- Name: pk_logtypeid; Type: CONSTRAINT; Schema: public; Owner: tarif; Tablespace:
--

ALTER TABLE ONLY logtype
    ADD CONSTRAINT pk_logtypeid PRIMARY KEY (id);


--
-- TOC entry 1834 (class 2606 OID 16421)
-- Dependencies: 1532 1532
-- Name: pk_whid; Type: CONSTRAINT; Schema: public; Owner: tarif; Tablespace:
--

ALTER TABLE ONLY whitelist
    ADD CONSTRAINT pk_whid PRIMARY KEY (id);


--
-- TOC entry 1851 (class 2606 OID 16568)
-- Dependencies: 1540 1540
-- Name: seanses_pkey; Type: CONSTRAINT; Schema: public; Owner: tarif; Tablespace:
--

ALTER TABLE ONLY seanses
    ADD CONSTRAINT seanses_pkey PRIMARY KEY (id);


--
-- TOC entry 1846 (class 2606 OID 16560)
-- Dependencies: 1538 1538
-- Name: services_name_key; Type: CONSTRAINT; Schema: public; Owner: tarif; Tablespace:
--

ALTER TABLE ONLY services
    ADD CONSTRAINT services_name_key UNIQUE (name);


--
-- TOC entry 1848 (class 2606 OID 16555)
-- Dependencies: 1538 1538
-- Name: services_pkey; Type: CONSTRAINT; Schema: public; Owner: tarif; Tablespace:
--

ALTER TABLE ONLY services
    ADD CONSTRAINT services_pkey PRIMARY KEY (id);


--
-- TOC entry 1836 (class 2606 OID 16543)
-- Dependencies: 1532 1532
-- Name: uniq_wl;host; Type: CONSTRAINT; Schema: public; Owner: tarif; Tablespace:
--

ALTER TABLE ONLY whitelist
    ADD CONSTRAINT "uniq_wl;host" UNIQUE (host);


--
-- TOC entry 1849 (class 1259 OID 16587)
-- Dependencies: 1540
-- Name: fki_servicetypeid; Type: INDEX; Schema: public; Owner: tarif; Tablespace:
--

CREATE INDEX fki_servicetypeid ON seanses USING btree (servicetypeid);


--
-- TOC entry 1828 (class 1259 OID 16410)
-- Dependencies: 1528
-- Name: fki_typeid; Type: INDEX; Schema: public; Owner: tarif; Tablespace:
--

CREATE INDEX fki_typeid ON log USING btree (typeid);


--
-- TOC entry 1857 (class 2606 OID 16569)
-- Dependencies: 1843 1540 1536
-- Name: fk_devid; Type: FK CONSTRAINT; Schema: public; Owner: tarif
--

ALTER TABLE ONLY seanses
    ADD CONSTRAINT fk_devid FOREIGN KEY (deviceid) REFERENCES devices(id);


--
-- TOC entry 1858 (class 2606 OID 16582)
-- Dependencies: 1847 1538 1540
-- Name: fk_servicetypeid; Type: FK CONSTRAINT; Schema: public; Owner: tarif
--

ALTER TABLE ONLY seanses
    ADD CONSTRAINT fk_servicetypeid FOREIGN KEY (servicetypeid) REFERENCES services(id);


--
-- TOC entry 1856 (class 2606 OID 16405)
-- Dependencies: 1528 1530 1831
-- Name: fk_typeid; Type: FK CONSTRAINT; Schema: public; Owner: tarif
--

ALTER TABLE ONLY log
    ADD CONSTRAINT fk_typeid FOREIGN KEY (typeid) REFERENCES logtype(id);


--
-- TOC entry 1871 (class 0 OID 0)
-- Dependencies: 3
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2011-09-26 17:19:18 MSK

--
-- PostgreSQL database dump complete
--

