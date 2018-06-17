FROM ruby:2.5

MAINTAINER sainu@pressblog.co.jp

ENV LANG C.UTF-8

RUN apt-get update -qq

WORKDIR /tmp
ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
RUN bundle install

ENV APP_DIR /app
RUN mkdir -p $APP_DIR
WORKDIR $APP_DIR
ADD . $APP_DIR
