--
-- PostgreSQL database dump
--

-- Dumped from database version 10.2 (Debian 10.2-1.pgdg90+1)
-- Dumped by pg_dump version 10.2 (Debian 10.2-1.pgdg90+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: tablefunc; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS tablefunc WITH SCHEMA public;


--
-- Name: EXTENSION tablefunc; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION tablefunc IS 'functions that manipulate whole tables, including crosstab';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE codes (
    id integer NOT NULL,
    level_id integer NOT NULL,
    code character varying(255)[] NOT NULL,
    bonus integer DEFAULT 0,
    main boolean DEFAULT true NOT NULL,
    hint text,
    title text,
    note text,
    number integer,
    sektor text DEFAULT 'Локация'::text NOT NULL,
    ko character varying(64) DEFAULT 'х.з.'::character varying NOT NULL
);


--
-- Name: codes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE codes_id_seq OWNED BY codes.id;


--
-- Name: files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE files (
    id integer NOT NULL,
    name text NOT NULL,
    path text NOT NULL,
    game_id integer NOT NULL
);


--
-- Name: files_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE files_id_seq OWNED BY files.id;


--
-- Name: game_reg; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE game_reg (
    id integer NOT NULL,
    team_id integer NOT NULL,
    game_id integer NOT NULL,
    adopt boolean DEFAULT true NOT NULL
);


--
-- Name: game_reg_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE game_reg_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: game_reg_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE game_reg_id_seq OWNED BY game_reg.id;


--
-- Name: gamelog; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE gamelog (
    id integer NOT NULL,
    ts timestamp without time zone NOT NULL,
    game_id integer NOT NULL,
    level_id integer,
    team_id integer,
    user_id integer,
    code_id integer,
    input text,
    action character varying(50),
    msg text,
    valid boolean DEFAULT false NOT NULL
);


--
-- Name: gamelog_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE gamelog_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gamelog_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE gamelog_id_seq OWNED BY gamelog.id;


--
-- Name: gameowner; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE gameowner (
    id integer NOT NULL,
    game_id integer NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: gameowner_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE gameowner_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gameowner_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE gameowner_id_seq OWNED BY gameowner.id;


--
-- Name: games; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE games (
    id integer NOT NULL,
    title text NOT NULL,
    anounce text NOT NULL,
    start timestamp without time zone NOT NULL,
    stop timestamp without time zone NOT NULL,
    team_id integer,
    closed boolean DEFAULT false NOT NULL
);


--
-- Name: games_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE games_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: games_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE games_id_seq OWNED BY games.id;


--
-- Name: hints; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE hints (
    id integer NOT NULL,
    level_id integer NOT NULL,
    title text,
    text text,
    timer integer DEFAULT 600
);


--
-- Name: hints_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE hints_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hints_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE hints_id_seq OWNED BY hints.id;


--
-- Name: levels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE levels (
    id integer NOT NULL,
    game_id integer NOT NULL,
    title text NOT NULL,
    number integer,
    sequence integer,
    type character varying(30) DEFAULT 'standart'::character varying,
    question text,
    spoiler text,
    answer character varying(255)[],
    duration integer DEFAULT 3600,
    need_codes integer DEFAULT 0 NOT NULL,
    penalty integer DEFAULT 0 NOT NULL,
    hide_title boolean DEFAULT false NOT NULL,
    code_hint_timer integer DEFAULT 0 NOT NULL
);


--
-- Name: levels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE levels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: levels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE levels_id_seq OWNED BY levels.id;


--
-- Name: status; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE status (
    id integer NOT NULL,
    game_id integer NOT NULL,
    team_id integer NOT NULL,
    level_id integer NOT NULL,
    enter timestamp without time zone,
    spoiler timestamp without time zone,
    pause_time integer DEFAULT 0,
    pause_at timestamp without time zone,
    "end" timestamp without time zone,
    bonus integer DEFAULT 0,
    penalty integer DEFAULT 0
);


--
-- Name: status_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE status_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE status_id_seq OWNED BY status.id;


--
-- Name: teams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE teams (
    id integer NOT NULL,
    title text NOT NULL,
    active_game integer
);


--
-- Name: teams_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE teams_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: teams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE teams_id_seq OWNED BY teams.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE users (
    id integer NOT NULL,
    login text NOT NULL,
    password text DEFAULT ''::text NOT NULL,
    team_id integer,
    captain boolean DEFAULT false NOT NULL,
    team_adopt boolean DEFAULT false NOT NULL,
    admin boolean DEFAULT false NOT NULL,
    title text DEFAULT 'Чупакабра'::text NOT NULL,
    theme character varying(32) DEFAULT 'default'::character varying NOT NULL,
    tgid integer
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: codes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY codes ALTER COLUMN id SET DEFAULT nextval('codes_id_seq'::regclass);


--
-- Name: files id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY files ALTER COLUMN id SET DEFAULT nextval('files_id_seq'::regclass);


--
-- Name: game_reg id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY game_reg ALTER COLUMN id SET DEFAULT nextval('game_reg_id_seq'::regclass);


--
-- Name: gamelog id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY gamelog ALTER COLUMN id SET DEFAULT nextval('gamelog_id_seq'::regclass);


--
-- Name: gameowner id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY gameowner ALTER COLUMN id SET DEFAULT nextval('gameowner_id_seq'::regclass);


--
-- Name: games id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY games ALTER COLUMN id SET DEFAULT nextval('games_id_seq'::regclass);


--
-- Name: hints id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY hints ALTER COLUMN id SET DEFAULT nextval('hints_id_seq'::regclass);


--
-- Name: levels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY levels ALTER COLUMN id SET DEFAULT nextval('levels_id_seq'::regclass);


--
-- Name: status id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY status ALTER COLUMN id SET DEFAULT nextval('status_id_seq'::regclass);


--
-- Name: teams id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY teams ALTER COLUMN id SET DEFAULT nextval('teams_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: codes codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY codes
    ADD CONSTRAINT codes_pkey PRIMARY KEY (id);


--
-- Name: files files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY files
    ADD CONSTRAINT files_pkey PRIMARY KEY (id);


--
-- Name: game_reg game_reg_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY game_reg
    ADD CONSTRAINT game_reg_pkey PRIMARY KEY (id);


--
-- Name: gamelog gamelog_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gamelog
    ADD CONSTRAINT gamelog_pkey PRIMARY KEY (id);


--
-- Name: gameowner gameowner_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gameowner
    ADD CONSTRAINT gameowner_pkey PRIMARY KEY (id);


--
-- Name: games games_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY games
    ADD CONSTRAINT games_pkey PRIMARY KEY (id);


--
-- Name: hints hints_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY hints
    ADD CONSTRAINT hints_pkey PRIMARY KEY (id);


--
-- Name: levels levels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY levels
    ADD CONSTRAINT levels_pkey PRIMARY KEY (id);


--
-- Name: status status_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY status
    ADD CONSTRAINT status_pkey PRIMARY KEY (id);


--
-- Name: teams teams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: codes_id_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX codes_id_uindex ON codes USING btree (id);


--
-- Name: files_id_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX files_id_uindex ON files USING btree (id);


--
-- Name: game_reg_id_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX game_reg_id_uindex ON game_reg USING btree (id);


--
-- Name: game_reg_team_id_game_id_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX game_reg_team_id_game_id_uindex ON game_reg USING btree (team_id, game_id);


--
-- Name: gamelog_id_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX gamelog_id_uindex ON gamelog USING btree (id);


--
-- Name: gameowner_game_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX gameowner_game_id_index ON gameowner USING btree (game_id);


--
-- Name: gameowner_id_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX gameowner_id_uindex ON gameowner USING btree (id);


--
-- Name: gameowner_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX gameowner_user_id_index ON gameowner USING btree (user_id);


--
-- Name: games_id_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX games_id_uindex ON games USING btree (id);


--
-- Name: hints_id_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX hints_id_uindex ON hints USING btree (id);


--
-- Name: levels_id_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX levels_id_uindex ON levels USING btree (id);


--
-- Name: status_id_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX status_id_uindex ON status USING btree (id);


--
-- Name: teams_id_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX teams_id_uindex ON teams USING btree (id);


--
-- Name: teams_title_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX teams_title_uindex ON teams USING btree (title);


--
-- Name: users_id_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_id_uindex ON users USING btree (id);


--
-- Name: users_login_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_login_uindex ON users USING btree (login);


--
-- Name: files files_games_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY files
    ADD CONSTRAINT files_games_id_fk FOREIGN KEY (game_id) REFERENCES games(id);


--
-- Name: game_reg game_reg_games_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY game_reg
    ADD CONSTRAINT game_reg_games_id_fk FOREIGN KEY (game_id) REFERENCES games(id);


--
-- Name: game_reg game_reg_teams_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY game_reg
    ADD CONSTRAINT game_reg_teams_id_fk FOREIGN KEY (team_id) REFERENCES teams(id);


--
-- Name: gameowner gameowner_games_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gameowner
    ADD CONSTRAINT gameowner_games_id_fk FOREIGN KEY (game_id) REFERENCES games(id);


--
-- Name: gameowner gameowner_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gameowner
    ADD CONSTRAINT gameowner_users_id_fk FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: levels levels_games_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY levels
    ADD CONSTRAINT levels_games_id_fk FOREIGN KEY (game_id) REFERENCES games(id);


--
-- PostgreSQL database dump complete
--

