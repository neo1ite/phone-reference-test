$(function(){
    $('.sorting, .sorting_asc, .sorting_desc').click(function(){
        var params = {};

        $.each(document.location.search.substr(1).split('&'), function(c, q) {
          var i = q.split('=').map(function(x){ return x.toString(); });
          if (i[1]) params[i[0]] = i[1];
        });

        params['sort']    = $(this).hasClass('sorting_asc') ? 'd' : 'a';
        params['sort_by'] = $(this).attr('id');
console.log($(this).attr('class'));

        window.location = '/?' + Object.keys(params).map(function(x){return x + '=' + params[x];}).join('&');
    });
});
