# Programming

------

# It's Social

------

### Good Morning, Garrett

```erlang
handle_amqp(#message{name="db.create"}=Msg, State) ->
    e2_log:info({db_create, stax_service:to_proplist(Msg)}),
    Name = get_required_attr("name", Msg),
    verify_db_name(Name),
    User = get_required_attr("user", Msg),
    Pwd = get_required_attr("password", Msg),
    Options =
        case get_attr("cluster", Msg) of
            undefined -> [];
            Cluster -> [{cluster, Cluster}]
        end,
    case stax_mysql_controller:create_database(
           Name, User, Pwd, Options) of
        {ok, HostInfo} ->
            Attrs = [{"slaves", ""}|host_info_attrs(HostInfo)],
            {reply, message_response(Msg, Attrs), State};
        {error, Err} ->
            e2_log:error({db_create, Err, erlang:get_stacktrace()}),
            {error, Err, State}
    end.
```

------

## Making our code social

------

### What's Going On Here?

```erlang
handle_amqp(#message{name="db.create"}=Msg, State) ->
    e2_log:info({db_create, stax_service:to_proplist(Msg)}),
    Name = get_required_attr("name", Msg),
    verify_db_name(Name),
    User = get_required_attr("user", Msg),
    Pwd = get_required_attr("password", Msg),
    Options =
        case get_attr("cluster", Msg) of
            undefined -> [];
            Cluster -> [{cluster, Cluster}]
        end,
    case stax_mysql_controller:create_database(
           Name, User, Pwd, Options) of
        {ok, HostInfo} ->
            Attrs = [{"slaves", ""}|host_info_attrs(HostInfo)],
            {reply, message_response(Msg, Attrs), State};
        {error, Err} ->
            e2_log:error({db_create, Err, erlang:get_stacktrace()}),
            {error, Err, State}
    end.
```

------

### This is What's Going On

```erlang
handle_amqp(#message{name="db.create"}=Msg, State) ->
    handle_db_create_msg(Msg, State).
```

------

# Done!

------

# <strike>Done!</strike>

## Not Just Yet

------

### Actualling Handling *DB Create*

------

### What's Going On Here?

```erlang
handle_db_create_msg(Msg, State) ->
    e2_log:info({db_create, stax_service:to_proplist(Msg)}),
    Name = get_required_attr("name", Msg),
    verify_db_name(Name),
    User = get_required_attr("user", Msg),
    Pwd = get_required_attr("password", Msg),
    Options =
        case get_attr("cluster", Msg) of
            undefined -> [];
            Cluster -> [{cluster, Cluster}]
        end,
    case stax_mysql_controller:create_database(
           Name, User, Pwd, Options) of
        {ok, HostInfo} ->
            Attrs = [{"slaves", ""}|host_info_attrs(HostInfo)],
            {reply, message_response(Msg, Attrs), State};
        {error, Err} ->
            e2_log:error({db_create, Err, erlang:get_stacktrace()}),
            {error, Err, State}
    end.
```

------

### This is What's Going On

```erlang
handle_db_create_msg(Msg, State) ->
    log_info(db_create, Msg),
    Args = db_create_args(Msg),
    handle_db_create(db_create(Args), Msg, State).
```

------

# Done!

------

# <strike>Done!</strike>

## Not Just Yet

------

## The *DB Create* Arguments

------

### *DB Create* Args, Naively

```erlang
db_create_args(Msg) ->
    Name = get_required_attr("name", Msg),
    verify_db_name(Name),
    User = get_required_attr("user", Msg),
    Pwd = get_required_attr("password", Msg),
    Options =
        case get_attr("cluster", Msg) of
            undefined -> [];
            Cluster -> [{cluster, Cluster}]
        end,
    #db_create{
      name=Name,
      user=User,
      pwd=Pwd,
      options=Options}.
```

------

### *DB Create* Args, Clearer

```erlang
db_create_args(Msg) ->
    #db_create{
      name=db_create_name_arg(Msg),
      user=db_create_user_arg(Msg),
      pwd=db_create_pwd_arg(Msg),
      options=db_create_options_arg(Msg)}.
```

------

### *DB Create* Args, Clearer Still

```erlang
db_create_args(Msg) ->
    #db_create{
      name    = db_create_name_arg(Msg),
      user    = db_create_user_arg(Msg),
      pwd     = db_create_pwd_arg(Msg),
      options = db_create_options_arg(Msg)}.
```

------

### *Name* Arg

```erlang
db_create_name_arg(Msg) ->
    verify_db_name(get_required_attr("name", Msg)).
```

------

### *User* Arg

```erlang
db_create_user_arg(Msg) ->
    get_required_attr("user", Msg).
```

------

### *Password* Arg

```erlang
db_create_pwd_arg(Msg) ->
    get_required_attr("password", Msg).
```

------

### *Options* Arg

```erlang
db_create_options_arg(Msg) ->
    case get_attr("cluster", Msg) of
        undefined -> [];
        Cluster -> [{cluster, Cluster}]
    end.
```

------

### *Options* Arg, Case Free

```erlang
db_create_options_arg(Msg) ->
    cluster_option(get_attr("cluster", Msg)).
```

------

## Functions are named case expressions

------

### A Named Case Expression

```erlang
cluster_option(undefined) -> [];
cluster_option(Cluster) -> [{cluster, Cluster}].
```

------

### Back to Our Message Handler

```erlang
handle_db_create_msg(Msg, State) ->
    log_info(db_create, Msg),
    Args = db_create_args(Msg),
    handle_db_create(db_create(Args), Msg, State).
```

------

### Pass-Through to External Function

```erlang
db_create(#db_create{name=Name, user=User, pwd=Pwd, options=Opts}) ->
    stax_mysql_controller:create_database(Name, User, Pwd, Opts).
```

------

### Handling the Result --- Original Code

```erlang
    case stax_mysql_controller:create_database(
           Name, User, Pwd, Options) of
        {ok, HostInfo} ->
            Attrs = [{"slaves", ""}|host_info_attrs(HostInfo)],
            {reply, message_response(Msg, Attrs), State};
        {error, Err} ->
            e2_log:error({db_create, Err, erlang:get_stacktrace()}),
            {error, Err, State}
    end
```

------

### Handling the Result --- A Function

```erlang
handle_db_create({ok, HostInfo}, Msg, State) ->
    Attrs = [{"slaves", ""}|host_info_attrs(HostInfo)],
    {reply, message_response(Msg, Attrs), State};
handle_db_create({error, Err}, _Msg, State) ->
    e2_log:error({db_create, Err, erlang:get_stacktrace()}),
    {error, Err, State}.
```

------

### Handling the Result --- Clearer Function

```erlang
handle_db_create({ok, HostInfo}, Msg, State) ->
    handle_db_created(HostInfo, Msg, State);
handle_db_create({error, Err}, _Msg, State) ->
    handle_db_create_error(Err, State).
```
------

### Handling the Success Case

```erlang
handle_db_created(HostInfo, Msg, State) ->
    Attrs = [{"slaves", ""}|host_info_attrs(HostInfo)],
    {reply, message_response(Msg, Attrs), State}.
```

------

### Handling the Success Case - Clearer

```erlang
handle_db_created(HostInfo, Msg, State) ->
    {reply, db_created_response(HostInfo, Msg), State}.
```

------

### Success Response

```erlang
db_created_response(HostInfo, Msg) ->
    HostInfo = host_info_attrs(HostInfo),
    Attrs = apply_db_created_legacy_attrs(HostInfo),
    message_response(Msg, Attrs).
```
------

### `apply_db_created_legacy_attrs`

#### aka Functions are Good for Naming Decisions

------

### Spelling it Out

```erlang
apply_db_created_legacy_attrs(Attrs) -> [{"slaves", ""}|Attrs].
```

------

### Handling the Error Case

```erlang
handle_db_create_error(Err, State) ->
    e2_log:error({db_create, Err, erlang:get_stacktrace()}),
    {error, Err, State}.
```

------

### Handling the Error Case --- Clearer

```erlang
handle_db_create_error(Err, State) ->
    log_error(db_create, Err),
    {error, Err, State}.
```

------

### The Original Function

```erlang
handle_amqp(#message{name="db.create"}=Msg, State) ->
    e2_log:info({db_create, stax_service:to_proplist(Msg)}),
    Name = get_required_attr("name", Msg),
    verify_db_name(Name),
    User = get_required_attr("user", Msg),
    Pwd = get_required_attr("password", Msg),
    Options =
        case get_attr("cluster", Msg) of
            undefined -> [];
            Cluster -> [{cluster, Cluster}]
        end,
    case stax_mysql_controller:create_database(
           Name, User, Pwd, Options) of
        {ok, HostInfo} ->
            Attrs = [{"slaves", ""}|host_info_attrs(HostInfo)],
            {reply, message_response(Msg, Attrs), State};
        {error, Err} ->
            e2_log:error({db_create, Err, erlang:get_stacktrace()}),
            {error, Err, State}
    end.
```

------

### The New Functions

```erlang
handle_amqp(#message{name="db.create"}=Msg, State) ->
    handle_db_create_msg(Msg, State).

handle_db_create_msg(Msg, State) ->
    log_info(db_create, Msg),
    Args = db_create_args(Msg),
    handle_db_create(db_create(Args), Msg, State).

log_info(Operation, Msg) ->
    e2_log:info({Operation, stax_service:to_proplist(Msg)}).

db_create_args(Msg) ->
    #db_create{
      name    = db_create_name_arg(Msg),
      user    = db_create_user_arg(Msg),
      pwd     = db_create_pwd_arg(Msg),
      options = db_create_options_arg(Msg)}.

db_create_name_arg(Msg) ->
    verify_db_name(get_required_attr("name", Msg)).

db_create_user_arg(Msg) ->
    get_required_attr("user", Msg).

db_create_pwd_arg(Msg) ->
    get_required_attr("password", Msg).

db_create_options_arg(Msg) ->
    cluster_option(get_attr("cluster", Msg)).

cluster_option(undefined) -> [];
cluster_option(Cluster) -> [{cluster, Cluster}].

db_create(#db_create{name=Name, user=User, pwd=Pwd, options=Opts}) ->
    stax_mysql_controller:create_database(Name, User, Pwd, Opts).

handle_db_create({ok, HostInfo}, Msg, State) ->
    handle_db_created(HostInfo, Msg, State);
handle_db_create({error, Err}, _Msg, State) ->
    handle_db_create_error(Err, State).

handle_db_created(HostInfo, Msg, State) ->
    {reply, db_created_response(HostInfo, Msg), State}.

db_created_response(HostInfo, Msg) ->
    HostInfo = host_info_attrs(HostInfo),
    Attrs = apply_db_created_legacy_attrs(HostInfo),
    message_response(Msg, Attrs).

apply_db_created_legacy_attrs(Attrs) -> [{"slaves", ""}|Attrs].

handle_db_create_error(Err, State) ->
    log_error(db_create, Err),
    {error, Err, State}.

log_error(Type, Err) ->
    e2_log:error({Type, Err}).
```

------

## Lots More Functions!

------

## Much Shorter Functions

------

## Clear, Respectful, Empathetic, Human Code

------

# Social

------

### The Big Picture

```erlang
handle_amqp(#message{name="db.create"}=Msg, State) ->
    handle_db_create_msg(Msg, State).

handle_db_create_msg(Msg, State) ->
    log_info(db_create, Msg),
    Args = db_create_args(Msg),
    handle_db_create(db_create(Args), Msg, State).
```

------

### Args

```erlang
db_create_args(Msg) ->
    #db_create{
      name    = db_create_name_arg(Msg),
      user    = db_create_user_arg(Msg),
      pwd     = db_create_pwd_arg(Msg),
      options = db_create_options_arg(Msg)}.

db_create_name_arg(Msg) ->
    verify_db_name(get_required_attr("name", Msg)).

db_create_user_arg(Msg) ->
    get_required_attr("user", Msg).

db_create_pwd_arg(Msg) ->
    get_required_attr("password", Msg).

db_create_options_arg(Msg) ->
    cluster_option(get_attr("cluster", Msg)).

cluster_option(undefined) -> [];
cluster_option(Cluster) -> [{cluster, Cluster}].
```

------

### Creating the DB, Handling the Result

```erlang
db_create(#db_create{name=Name, user=User, pwd=Pwd, options=Opts}) ->
    stax_mysql_controller:create_database(Name, User, Pwd, Opts).

handle_db_create({ok, HostInfo}, Msg, State) ->
    handle_db_created(HostInfo, Msg, State);
handle_db_create({error, Err}, _Msg, State) ->
    handle_db_create_error(Err, State).

handle_db_created(HostInfo, Msg, State) ->
    {reply, db_created_response(HostInfo, Msg), State}.

handle_db_create_error(Err, State) ->
    log_error(db_create, Err),
    {error, Err, State}.
```

------

### Sundries

```erlang
db_created_response(HostInfo, Msg) ->
    HostInfo = host_info_attrs(HostInfo),
    Attrs = apply_db_created_legacy_attrs(HostInfo),
    message_response(Msg, Attrs).

apply_db_created_legacy_attrs(Attrs) -> [{"slaves", ""}|Attrs].

log_info(Operation, Msg) ->
    e2_log:info({Operation, stax_service:to_proplist(Msg)}).

log_error(Type, Err) ->
    e2_log:error({Type, Err}).
```

------

## Too many functions

------

## You can do this with any language

------

## Why

- It's social
- <strike>Easier</strike> Possible to change
- <strike>Easier</strike> Possible to debug
- Easier to test
- Less testing (less fear)

------

# Questions?

------

### Break 1 Winners

```
886710
886711
886714
886716
886739
886749
886753
886768
886781
886782
886786
```

------

### Break 2 Winners

```
886791
886797
886804
886822
886826
886848
886861
886876
886890
886896
886909
```

------

### Extra Winners

```
886705
886715
886726
886773
886775
886777
886789
886800
886815
886824
886830
886839
886863
886868
886878
886882
886906
886907

```
