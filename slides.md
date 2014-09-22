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

### Make Logging Obvious

```erlang
log_info(Operation, Msg) ->
    e2_log:info({Operation, stax_service:to_proplist(Msg)}).
```

------

### *Create DB* Args, Naively

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

### Erlang *Record* --- for the Args

Define It

```erlang
-record(db_create, {name, user, pwd, options}).
```

Use It

```erlang
#db_create{
  name=Name,
  user=User,
  pwd=Pwd,
  options=Options}
```

------

### *Create DB* Args, Clearer

```erlang
db_create_args(Msg) ->
    #db_create{
      name=db_create_name_arg(Msg),
      user=db_create_user_arg(Msg),
      pwd=db_create_pwd_arg(Msg),
      options=db_create_options_arg(Msg)}.
```

------

### *Create DB* Args, Clearer Still

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
db_create_name_arg(Msg, Args) ->
    verify_db_name(get_required_attr("name", Msg)).
```

------

### *User* Arg

```erlang
db_create_user_arg(Msg, Args) ->
    get_required_attr("user", Msg).
```

------

### *Password* Arg

```erlang
db_create_pwd_arg(Msg, Args) ->
    get_required_attr("password", Msg).
```

------

### *Options* Arg

```erlang
db_create_options_arg(Msg, Args) ->
    case get_attr("cluster", Msg) of
        undefined -> [];
        Cluster -> [{cluster, Cluster}]
    end.
```

------

### *Options* Arg, Case Free

```erlang
db_create_options_arg(Msg, Args) ->
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

### Recap

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

### Handling the Result --- What's Going On?

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

### Handling the Result --- What's Going On?

```erlang
handle_db_create({ok, HostInfo}, Msg, State) ->
    Attrs = [{"slaves", ""}|host_info_attrs(HostInfo)],
    {reply, message_response(Msg, Attrs), State};
handle_db_create({error, Err}, _Msg, State) ->
    e2_log:error({db_create, Err, erlang:get_stacktrace()}),
    {error, Err, State}.
```

------

### Handling the Result --- What's Going On

```erlang
handle_db_create({ok, HostInfo}, Msg, State) ->
    handle_db_created(HostInfo, Msg, State);
handle_db_create({error, Err}, _Msg, State) ->
    handle_db_create_error(Err, State).
```
------

```erlang
handle_db_created(HostInfo, Msg, State) ->
    Attrs = [{"slaves", ""}|host_info_attrs(HostInfo)],
    {reply, message_response(Msg, Attrs), State}.
```

------

```erlang
handle_db_created(HostInfo, Msg, State) ->
    {reply, db_created_response(HostInfo, Msg), State}.
```

------

```erlang
db_created_response(HostInfo, Msg) ->
    message_response(Msg, db_created_response_attrs(HostInfo)).
```

------

```erlang
db_created_response_attrs(HostInfo) ->
    db_created_legacy_attrs(host_info_attrs(HostInfo)).
```

------

```erlang
db_created_legacy_attrs(Attrs) -> [{"slaves", ""}|Attrs].
```

------

```erlang
handle_db_create_error(Err, State) ->
    e2_log:error({db_create, Err, erlang:get_stacktrace()}),
    {error, Err, State}.
```

------

```erlang
handle_db_create_error(Err, State) ->
    log_error(db_create, Err),
    {error, Err, State}.
```

------

```erlang
log_error(Type, Err) ->
    e2_log:error({Type, Err, erlang:get_stacktrace()}).
```

------

### `erlang:get_stacktrace/0`

> Get the call stack back-trace (stacktrace) of the last exception in the
> calling process… If there has not been any exceptions in a process, the
> stacktrace is [].

------

```erlang
log_error(Type, Err) ->
    e2_log:error({Type, Err}).
```

------

# Too Many Functions!

------

![](dog.jpg)
