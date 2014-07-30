CREATE TABLE action_logs (
    uid INTEGER NOT NULL DEFAULT 0,
    time INTEGER NOT NULL SORTKEY,
    type varchar(max),
    json varchar(max)
);
