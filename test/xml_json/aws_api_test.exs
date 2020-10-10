defmodule XmlJson.AwsApiTest do
  use ExUnit.Case
  use Placebo

  doctest XmlJson.AwsApi

  describe "deserialize/2" do
    test "absorbs all but text in an element and does not preserve newlines" do
      xml = """
      <root>
      dog
      <stuff>5</stuff>
       </root>
      """

      assert {:ok, %{"root" => "dog"}} == XmlJson.AwsApi.deserialize(xml)
    end

    test "sets empty elements as nil" do
      xml = """
      <root></root>
      """

      assert {:ok, %{"root" => nil}} == XmlJson.AwsApi.deserialize(xml)
    end

    test "sets newline-only elements as nil" do
      xml = """
      <root>

      </root>
      """

      assert {:ok, %{"root" => nil}} == XmlJson.AwsApi.deserialize(xml)
    end

    test "turns singular members into a list" do
      xml = """
      <root>
        <member>
          <cat>dog</cat>
        </member>
      </root>
      """

      assert {:ok, %{"root" => [%{"cat" => "dog"}]}} == XmlJson.AwsApi.deserialize(xml)
    end

    test "turns multiple members into a list" do
      xml = """
      <root>
      <member>
        <cat>dog</cat>
      </member>
        <member>
          <cat>pig</cat>
        </member>
      </root>
      """

      assert {:ok, %{"root" => [%{"cat" => "dog"}, %{"cat" => "pig"}]}} ==
               XmlJson.AwsApi.deserialize(xml)
    end

    test "turns a variety of member prefixes into a list" do
      xml = """
      <root>
        <animals>
          <member>
            <cat>dog</cat>
          </member>
          <member>
            <cat>pig</cat>
          </member>
        </animals>
        <people>
          <item>jeff</item>
          <item>balser</item>
        </people>
      </root>
      """

      assert {:ok,
              %{
                "root" => %{
                  "animals" => [%{"cat" => "dog"}, %{"cat" => "pig"}],
                  "people" => ["jeff", "balser"]
                }
              }} == XmlJson.AwsApi.deserialize(xml, list_element_names: ["member", "item"])
    end

    test "can handle a real-world example" do
      xml = """
      <DescribeListenersResponse xmlns="http://elasticloadbalancing.amazonaws.com/doc/2015-12-01/">
        <DescribeListenersResult>
          <Listeners>
            <member>
              <Port>443</Port>
              <Protocol>HTTPS</Protocol>
              <LoadBalancerArn>arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/app/my-load-balancer/50dc6c495c0c9188</LoadBalancerArn>
              <ListenerArn>arn:aws:elasticloadbalancing:us-west-2:123456789012:listener/app/my-load-balancer/50dc6c495c0c9188/f2f7dc8efc522ab2</ListenerArn>
              <DefaultActions>
                <member>
                  <Type>forward</Type>
                  <TargetGroupArn>arn:aws:elasticloadbalancing:us-west-2:123456789012:targetgroup/my-targets/73e2d6bc24d8a067</TargetGroupArn>
                </member>
              </DefaultActions>
              <SslPolicy>ELBSecurityPolicy-2016-08</SslPolicy>
              <Certificates>
                <member>
                  <CertificateArn>arn:aws:acm:us-west-2:123456789012:certificate/68c11a12-39de-44dd-b329-fe64aEXAMPLE</CertificateArn>
                </member>
              </Certificates>
            </member>
          </Listeners>
        </DescribeListenersResult>
        <ResponseMetadata>
          <RequestId>18e470d3-f39c-11e5-a53c-67205c0d10fd</RequestId>
        </ResponseMetadata>
      </DescribeListenersResponse>
      """

      map = %{
        "DescribeListenersResponse" => %{
          "DescribeListenersResult" => %{
            "Listeners" => [
              %{
                "Port" => 443,
                "Protocol" => "HTTPS",
                "LoadBalancerArn" =>
                  "arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/app/my-load-balancer/50dc6c495c0c9188",
                "ListenerArn" =>
                  "arn:aws:elasticloadbalancing:us-west-2:123456789012:listener/app/my-load-balancer/50dc6c495c0c9188/f2f7dc8efc522ab2",
                "DefaultActions" => [
                  %{
                    "Type" => "forward",
                    "TargetGroupArn" =>
                      "arn:aws:elasticloadbalancing:us-west-2:123456789012:targetgroup/my-targets/73e2d6bc24d8a067"
                  }
                ],
                "SslPolicy" => "ELBSecurityPolicy-2016-08",
                "Certificates" => [
                  %{
                    "CertificateArn" =>
                      "arn:aws:acm:us-west-2:123456789012:certificate/68c11a12-39de-44dd-b329-fe64aEXAMPLE"
                  }
                ]
              }
            ]
          },
          "ResponseMetadata" => %{
            "RequestId" => "18e470d3-f39c-11e5-a53c-67205c0d10fd"
          }
        }
      }

      assert {:ok, map} == XmlJson.AwsApi.deserialize(xml)
    end

    test "handles another real world example" do
      xml = """
      <CreateLoadBalancerResponse xmlns="http://elasticloadbalancing.amazonaws.com/doc/2015-12-01/">
        <CreateLoadBalancerResult>
          <LoadBalancers>
            <member>
              <LoadBalancerArn>arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/app/my-internal-load-balancer/50dc6c495c0c9188</LoadBalancerArn>
              <Scheme>internet-facing</Scheme>
              <LoadBalancerName>my-load-balancer</LoadBalancerName>
              <VpcId>vpc-3ac0fb5f</VpcId>
              <CanonicalHostedZoneId>Z2P70J7EXAMPLE</CanonicalHostedZoneId>
              <CreatedTime>2016-03-25T21:29:48.850Z</CreatedTime>
              <AvailabilityZones>
                <member>
                  <SubnetId>subnet-8360a9e7</SubnetId>
                  <ZoneName>us-west-2a</ZoneName>
                </member>
                <member>
                  <SubnetId>subnet-b7d581c0</SubnetId>
                  <ZoneName>us-west-2b</ZoneName>
                </member>
              </AvailabilityZones>
              <SecurityGroups>
                <member>sg-5943793c</member>
              </SecurityGroups>
              <DNSName>my-load-balancer-424835706.us-west-2.elb.amazonaws.com</DNSName>
              <State>
                <Code>provisioning</Code>
              </State>
              <Type>application</Type>
            </member>
          </LoadBalancers>
        </CreateLoadBalancerResult>
        <ResponseMetadata>
          <RequestId>32d531b2-f2d0-11e5-9192-3fff33344cfa</RequestId>
        </ResponseMetadata>
      </CreateLoadBalancerResponse>
      """

      map = %{
        "CreateLoadBalancerResponse" => %{
          "CreateLoadBalancerResult" => %{
            "LoadBalancers" => [
              %{
                "AvailabilityZones" => [
                  %{"SubnetId" => "subnet-8360a9e7", "ZoneName" => "us-west-2a"},
                  %{"SubnetId" => "subnet-b7d581c0", "ZoneName" => "us-west-2b"}
                ],
                "CanonicalHostedZoneId" => "Z2P70J7EXAMPLE",
                "CreatedTime" => "2016-03-25T21:29:48.850Z",
                "DNSName" => "my-load-balancer-424835706.us-west-2.elb.amazonaws.com",
                "LoadBalancerArn" =>
                  "arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/app/my-internal-load-balancer/50dc6c495c0c9188",
                "LoadBalancerName" => "my-load-balancer",
                "Scheme" => "internet-facing",
                "SecurityGroups" => ["sg-5943793c"],
                "State" => %{"Code" => "provisioning"},
                "Type" => "application",
                "VpcId" => "vpc-3ac0fb5f"
              }
            ]
          },
          "ResponseMetadata" => %{"RequestId" => "32d531b2-f2d0-11e5-9192-3fff33344cfa"}
        }
      }

      assert {:ok, map} == XmlJson.AwsApi.deserialize(xml)
    end
  end

  describe "serialize/2" do
    test "returns an error when XML cannot be formed" do
      allow Saxy.encode!(any()), exec: fn _ -> raise "something unexpected" end

      assert {:error, _} = XmlJson.AwsApi.serialize(%{"dog" => "cat"})
    end

    test "object properties become element names" do
      object = %{
        "root" => %{
          "dog" => %{"piglet" => "cat", "doglet" => "puppy"},
          "horse" => "fifteen"
        }
      }

      xml = """
      <root><dog><doglet>puppy</doglet><piglet>cat</piglet></dog><horse>fifteen</horse></root>
      """

      assert {:ok, String.trim(xml)} == XmlJson.AwsApi.serialize(object)
    end

    test "the text of a propert goes into the text of an element" do
      object = %{"alice" => "bob"}

      xml = """
      <alice>bob</alice>
      """

      assert {:ok, String.trim(xml)} == XmlJson.AwsApi.serialize(object)
    end

    test "nested properties become nested elements" do
      object = %{
        "alice" => %{
          "bob" => "charlie",
          "david" => "edgar"
        }
      }

      xml = """
      <alice><bob>charlie</bob><david>edgar</david></alice>
      """

      assert {:ok, String.trim(xml)} == XmlJson.AwsApi.serialize(object)
    end

    test "list properties are placed under member elements" do
      object = %{
        "alice" => [
          %{"bob" => "charlie"},
          %{"bob" => "edgar"}
        ]
      }

      xml = """
      <alice><member><bob>charlie</bob></member><member><bob>edgar</bob></member></alice>
      """

      assert {:ok, String.trim(xml)} == XmlJson.AwsApi.serialize(object)
    end

    test "list properties are placed under cycled, explicit member names" do
      object = %{
        "alice" => [
          %{"bob" => [%{"charlie" => ["chet"]}]},
          %{"bob" => [%{"charlie" => ["chaz"]}]}
        ]
      }

      xml = """
      <alice><first><bob><second><charlie><first>chet</first></charlie></second></bob></first><first><bob><second><charlie><first>chaz</first></charlie></second></bob></first></alice>
      """

      assert {:ok, String.trim(xml)} == XmlJson.AwsApi.serialize(object, list_element_names: ["first", "second"])
    end
  end

  describe "serialize_as_params/2" do
    test "uses dot notation to flatten maps" do
      map = %{
        "Map" => %{
          "DeepMap" => %{
            "Name" => "hello",
            "Address" => "value"
          }
        }
      }

      params = %{
        "Map.DeepMap.Name" => "hello",
        "Map.DeepMap.Address" => "value"
      }

      assert {:ok, params} == XmlJson.AwsApi.serialize_as_params(map)
    end

    test "uses list name to flatten lists" do
      map = %{
        "List" => [
          %{
            "DeepList" => [
              %{
                "Name" => "hello",
                "Address" => "value"
              }
            ]
          }
        ]
      }

      params = %{
        "List.member.1.DeepList.member.1.Name" => "hello",
        "List.member.1.DeepList.member.1.Address" => "value"
      }

      assert {:ok, params} == XmlJson.AwsApi.serialize_as_params(map)
    end

    test "cycles explicit list names at each level to flatten lists" do
      map = %{
        "List" => [
          %{
            "DeepList" => [
              %{
                "DeeperList" => [
                  %{
                    "Name" => "hello",
                    "Address" => "value"
                  }
                ]
              }
            ]
          }
        ]
      }

      params = %{
        "List.first.1.DeepList.second.1.DeeperList.first.1.Name" => "hello",
        "List.first.1.DeepList.second.1.DeeperList.first.1.Address" => "value"
      }

      assert {:ok, params} == XmlJson.AwsApi.serialize_as_params(map, list_element_names: ["first", "second"])
    end

    test "handles a real world example" do
      map = %{
        "Port" => 443,
        "Protocol" => "HTTPS",
        "LoadBalancerArn" =>
          "arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/app/my-load-balancer/50dc6c495c0c9188",
        "ListenerArn" =>
          "arn:aws:elasticloadbalancing:us-west-2:123456789012:listener/app/my-load-balancer/50dc6c495c0c9188/f2f7dc8efc522ab2",
        "DefaultActions" => [
          %{
            "Type" => "forward",
            "TargetGroupArn" =>
              "arn:aws:elasticloadbalancing:us-west-2:123456789012:targetgroup/my-targets/73e2d6bc24d8a067"
          }
        ],
        "SslPolicy" => "ELBSecurityPolicy-2016-08",
        "Certificates" => [
          %{
            "CertificateArn" =>
              "arn:aws:acm:us-west-2:123456789012:certificate/68c11a12-39de-44dd-b329-fe64aEXAMPLE"
          }
        ],
        "Tags" => [
          %{
            "Key" => "name",
            "Value" => "cool"
          },
          %{
            "Key" => "version",
            "Value" => "cool.0"
          }
        ]
      }

      params = %{
        "Port" => 443,
        "Protocol" => "HTTPS",
        "LoadBalancerArn" =>
          "arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/app/my-load-balancer/50dc6c495c0c9188",
        "ListenerArn" =>
          "arn:aws:elasticloadbalancing:us-west-2:123456789012:listener/app/my-load-balancer/50dc6c495c0c9188/f2f7dc8efc522ab2",
        "DefaultActions.member.1.Type" => "forward",
        "DefaultActions.member.1.TargetGroupArn" =>
          "arn:aws:elasticloadbalancing:us-west-2:123456789012:targetgroup/my-targets/73e2d6bc24d8a067",
        "SslPolicy" => "ELBSecurityPolicy-2016-08",
        "Certificates.member.1.CertificateArn" =>
          "arn:aws:acm:us-west-2:123456789012:certificate/68c11a12-39de-44dd-b329-fe64aEXAMPLE",
        "Tags.member.1.Key" => "name",
        "Tags.member.1.Value" => "cool",
        "Tags.member.2.Key" => "version",
        "Tags.member.2.Value" => "cool.0"
      }

      assert {:ok, params} == XmlJson.AwsApi.serialize_as_params(map)
    end

    test "handles another real world example" do
      map = %{
        "AvailabilityZones" => [
          %{"SubnetId" => "subnet-8360a9e7", "ZoneName" => "us-west-2a"},
          %{"SubnetId" => "subnet-b7d581c0", "ZoneName" => "us-west-2b"}
        ],
        "CanonicalHostedZoneId" => "Z2P70J7EXAMPLE",
        "CreatedTime" => "2016-03-25T21:29:48.850Z",
        "DNSName" => "my-load-balancer-424835706.us-west-2.elb.amazonaws.com",
        "LoadBalancerArn" =>
          "arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/app/my-internal-load-balancer/50dc6c495c0c9188",
        "Name" => "my-load-balancer",
        "Scheme" => "internet-facing",
        "SecurityGroups" => ["sg-5943793c"],
        "State" => %{"Code" => "provisioning"},
        "Type" => "application",
        "VpcId" => "vpc-3ac0fb5f"
      }

      params = %{
        "AvailabilityZones.member.1.SubnetId" => "subnet-8360a9e7",
        "AvailabilityZones.member.1.ZoneName" => "us-west-2a",
        "AvailabilityZones.member.2.SubnetId" => "subnet-b7d581c0",
        "AvailabilityZones.member.2.ZoneName" => "us-west-2b",
        "CanonicalHostedZoneId" => "Z2P70J7EXAMPLE",
        "CreatedTime" => "2016-03-25T21:29:48.850Z",
        "DNSName" => "my-load-balancer-424835706.us-west-2.elb.amazonaws.com",
        "LoadBalancerArn" =>
          "arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/app/my-internal-load-balancer/50dc6c495c0c9188",
        "Name" => "my-load-balancer",
        "Scheme" => "internet-facing",
        "SecurityGroups.member.1" => "sg-5943793c",
        "State.Code" => "provisioning",
        "Type" => "application",
        "VpcId" => "vpc-3ac0fb5f"
      }

      assert {:ok, params} == XmlJson.AwsApi.serialize_as_params(map)
    end
  end

end
